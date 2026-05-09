import 'dart:async';
import 'package:flutter/foundation.dart';
import '../proto/vehicle_frame.pb.dart';
import '../services/cluster_client.dart';

class VehicleFrameNotifier extends ChangeNotifier {
  final ClusterClient _client;
  StreamSubscription<VehicleFrame>? _subscription;
  VehicleFrame? _latest;
  String? _error;

  VehicleFrame? get latest => _latest;
  String? get error => _error;

  VehicleFrameNotifier(this._client) {
    _startListening();
  }

  void _startListening() {
    _subscription?.cancel();

    _subscription = _client.subscribe().listen(
      (frame) {
        _latest = frame;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
        // Zenoh handles reconnect internally, but keep this as fallback
        Future.delayed(const Duration(seconds: 3), _startListening);
      },
      onDone: () {
        Future.delayed(const Duration(seconds: 1), _startListening);
      },
      cancelOnError: false,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _client.shutdown();
    super.dispose();
  }
}