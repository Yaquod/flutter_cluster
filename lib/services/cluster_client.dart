// import 'dart:async';
// import 'package:zenoh_dart/zenoh_dart.dart';
// import '../proto/vehicle_frame.pb.dart';

// class ClusterClient {
//   final String keyExpr;
//   ZenohClient? _client;
//   ZenohSubscriber? _subscriber;
//   final _controller = StreamController<VehicleFrame>.broadcast();

//   ClusterClient({this.keyExpr = 'autoware/cluster'});

//   Stream<VehicleFrame> subscribe() {
//     _connect();
//     return _controller.stream;
//   }

//   Future<void> _connect() async {
//     try {
//      // _client = await ZenohClient.connect(ZenohConfig());
//    _client = await ZenohClient.connect(
//   ZenohConfig(
//     mode: ZenohMode.client,       // client mode since you're connecting to a specific peer
//     locator: "udp/127.0.0.1:7447",  // ← vehicle's IP
//   ),
// );

//       _subscriber = await _client!.subscribe(keyExpr);

//       _subscriber!.stream.listen(
//         (ZenohSample sample) {
//           try {
           
//             final frame = VehicleFrame.fromBuffer(sample.payload);
//             _controller.add(frame);
//           } catch (e) {
//             _controller.addError('Proto decode error: $e');
//           }
//         },
//         onError: (e) => _controller.addError('Zenoh stream error: $e'),
//       );
//     } catch (e) {
//       _controller.addError('Zenoh connect error: $e');
//     }
//   }

//   Future<void> shutdown() async {
//     if (_client != null && _subscriber != null) {
//       await _client!.undeclareSubscriber(_subscriber!);
//     }
//     await _client?.close();
//     await _controller.close();
//   }
// }

import 'dart:async';
import 'dart:isolate';
import 'dart:ffi';
import 'package:zenoh_dart/zenoh_dart.dart';
import '../proto/vehicle_frame.pb.dart';

class ClusterClient {
  final String keyExpr;
  ZenohClient? _client;
  ZenohSubscriber? _subscriber;
  final _controller = StreamController<VehicleFrame>.broadcast();
  bool _isConnected = false;
  bool _disposed = false;

  ClusterClient({this.keyExpr = 'autoware/cluster'});

  Stream<VehicleFrame> subscribe() {
    _connect().catchError((e) {
      _controller.addError('Connection failed: $e');
    });
    return _controller.stream;
  }

  Future<void> _connect() async {
    if (_isConnected || _disposed) return;
    _isConnected = true;

    try {
      _client = await ZenohClient.connect(
        ZenohConfig(
          mode: ZenohMode.client,
          locator: "udp/127.0.0.1:7447",
        ),
      );

      _subscriber = await _client!.subscribe(keyExpr);

      // Use a ReceivePort as a thread-safe bridge
      final receivePort = ReceivePort();
      final sendPort = receivePort.sendPort;

      // Listen on the Dart isolate side
      receivePort.listen((dynamic message) {
        if (_disposed) {
          receivePort.close();
          return;
        }
        if (message is List<int>) {
          try {
            final frame = VehicleFrame.fromBuffer(message);
            _controller.add(frame);
          } catch (e) {
            _controller.addError('Proto decode error: $e');
          }
        }
      });

      // Poll the zenoh stream using a Timer instead of stream.listen
      // This keeps everything on the Dart isolate thread
      Timer.periodic(const Duration(milliseconds: 10), (timer) async {
        if (_disposed) {
          timer.cancel();
          receivePort.close();
          return;
        }
        // Check for pending samples without blocking
        try {
          await for (final sample in _subscriber!.stream.timeout(
            const Duration(milliseconds: 1),
            onTimeout: (sink) => sink.close(),
          )) {
            if (!_disposed) {
              sendPort.send(sample.payload.toList());
            }
          }
        } catch (_) {
          // timeout is expected, continue
        }
      });

    } catch (e) {
      _isConnected = false;
      _controller.addError('Zenoh connect error: $e');
    }
  }

  Future<void> shutdown() async {
    _disposed = true;
    if (_client != null && _subscriber != null) {
      await _client!.undeclareSubscriber(_subscriber!);
    }
    await _client?.close();
    await _controller.close();
  }
}