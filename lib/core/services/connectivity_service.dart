import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final _connectivity = Connectivity();
  final ValueNotifier<bool> connectionStatus = ValueNotifier<bool>(true);
  bool get isConnected => connectionStatus.value;

  ConnectivityService() {
    checkConnectivity();
  }

  Future<void> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      connectionStatus.value = result != ConnectivityResult.none;
    } catch (e) {
      connectionStatus.value = false;
    }
  }

  void setupConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      connectionStatus.value = result != ConnectivityResult.none;
    });
  }
}
