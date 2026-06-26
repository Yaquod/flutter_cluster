import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:async';
import 'package:ffi/ffi.dart' as pkgffi;

typedef _InitApiNative = ffi.IntPtr Function(ffi.Pointer<ffi.Void>);
typedef _InitApi       = int      Function(ffi.Pointer<ffi.Void>);

typedef _StartNative = ffi.Int32 Function(
  ffi.Pointer<ffi.Char>,
  ffi.Pointer<ffi.Char>,
  ffi.Int64,
);
typedef _Start = int Function(
  ffi.Pointer<ffi.Char>,
  ffi.Pointer<ffi.Char>,
  int,
);

typedef _StopNative = ffi.Void Function();
typedef _Stop       = void    Function();

class ClusterClient {
  ClusterClient({
    this.locator = 'udp/127.0.0.1:7447',
    this.keyExpr  = 'autoware/cluster',
    this.libraryPath = 'libcluster_bridge.so',
  });

  final String locator;
  final String keyExpr;
  final String libraryPath;

  RawReceivePort?              _port;
  StreamController<Uint8List>? _controller;
  bool _running = false;

  late final ffi.DynamicLibrary _lib;
  late final _InitApi _initApi;
  late final _Start   _start;
  late final _Stop    _stop;

  ffi.DynamicLibrary _openLibrary() {
    var paths = [libraryPath];

    var exe = Platform.resolvedExecutable;
    var bundleLibDir = '${exe.substring(0, exe.lastIndexOf('/'))}/lib';
    paths.add('$bundleLibDir/libcluster_bridge.so');

    if (Platform.environment.containsKey('LD_LIBRARY_PATH')) {
      for (var dir in Platform.environment['LD_LIBRARY_PATH']!.split(':')) {
        paths.add('$dir/libcluster_bridge.so');
      }
    }

    for (var p in paths) {
      try {
        return ffi.DynamicLibrary.open(p);
      } catch (_) {
        continue;
      }
    }
    throw ArgumentError(
      'Failed to load libcluster_bridge.so from any path.\n'
      'Tried:\n  ${paths.join('\n  ')}\n'
      'Ensure the native bridge is built and in the library path.',
    );
  }

  Stream<Uint8List> subscribe() {
    if (_running) throw StateError('Already subscribed');

    try {
      _lib = _openLibrary();
    } catch (e) {
      _controller = StreamController<Uint8List>.broadcast();
      _controller!.addError(e);
      return _controller!.stream;
    }

    _initApi = _lib.lookupFunction<_InitApiNative, _InitApi>(
      'cluster_bridge_init_dart_api',
    );
    _start = _lib.lookupFunction<_StartNative, _Start>(
      'cluster_bridge_start',
    );
    _stop = _lib.lookupFunction<_StopNative, _Stop>(
      'cluster_bridge_stop',
    );

    // Initialize dart_api_dl BEFORE any Zenoh callbacks can fire
    _initApi(ffi.NativeApi.initializeApiDLData);

    _controller = StreamController<Uint8List>.broadcast();

    _port = RawReceivePort((dynamic msg) {
      if (msg is Uint8List && !(_controller!.isClosed)) {
        if (msg.isNotEmpty && msg[0] == 0x00) {
          String errMsg = 'bridge error: ${String.fromCharCodes(msg.sublist(1))}';
          _controller!.addError(errMsg);
        } else {
          _controller!.add(msg);
        }
      }
    });

    final locPtr = locator.toNativeUtf8(allocator: pkgffi.calloc);
    final keyPtr = keyExpr.toNativeUtf8(allocator: pkgffi.calloc);

    final rc = _start(
      locPtr.cast<ffi.Char>(),
      keyPtr.cast<ffi.Char>(),
      _port!.sendPort.nativePort,
    );

    pkgffi.calloc.free(locPtr);
    pkgffi.calloc.free(keyPtr);

    if (rc != 0) {
      _port!.close();
      _controller!.close();
      _controller = StreamController<Uint8List>.broadcast();
      _controller!.addError('cluster_bridge_start failed: code $rc');
      return _controller!.stream;
    }

    _running = true;
    return _controller!.stream;
  }

  void shutdown() {
    if (!_running) return;
    _running = false;
    _stop();
    _port?.close();
    _port = null;
    _controller?.close();
    _controller = null;
  }
}
