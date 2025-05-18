import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  final ValueNotifier<bool> connectionStatus = ValueNotifier<bool>(true);

  /// Checks the current internet connectivity status
  Future<void> checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    _isConnected = connectivityResult != ConnectivityResult.none;
    connectionStatus.value = _isConnected;
  }

  /// Sets up a listener for connectivity changes
  void setupConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      _isConnected = result != ConnectivityResult.none;
      connectionStatus.value = _isConnected;
    });
  }
}
