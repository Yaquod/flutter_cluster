import 'dart:async';
import 'package:zenoh_dart/zenoh_dart.dart';
import '../proto/vehicle_frame.pb.dart';

class ClusterClient {
  final String keyExpr;
  ZenohClient? _client;
  ZenohSubscriber? _subscriber;
  final _controller = StreamController<VehicleFrame>.broadcast();

  ClusterClient({this.keyExpr = 'autoware/cluster'});

  Stream<VehicleFrame> subscribe() {
    _connect();
    return _controller.stream;
  }

  Future<void> _connect() async {
    try {
      _client = await ZenohClient.connect(ZenohConfig());

      _subscriber = await _client!.subscribe(keyExpr);

      _subscriber!.stream.listen(
        (ZenohSample sample) {
          try {
           
            final frame = VehicleFrame.fromBuffer(sample.payload);
            _controller.add(frame);
          } catch (e) {
            _controller.addError('Proto decode error: $e');
          }
        },
        onError: (e) => _controller.addError('Zenoh stream error: $e'),
      );
    } catch (e) {
      _controller.addError('Zenoh connect error: $e');
    }
  }

  Future<void> shutdown() async {
    if (_client != null && _subscriber != null) {
      await _client!.undeclareSubscriber(_subscriber!);
    }
    await _client?.close();
    await _controller.close();
  }
}