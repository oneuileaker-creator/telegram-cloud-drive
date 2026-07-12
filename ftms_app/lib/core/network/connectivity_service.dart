import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'dart:async';

enum ConnectionStatus { online, offline, slow }

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._();
  static ConnectivityService get instance => _instance;
  ConnectivityService._();

  ConnectionStatus _status = ConnectionStatus.online;
  ConnectionStatus get status => _status;
  bool get isOnline => _status != ConnectionStatus.offline;

  StreamSubscription? _sub;

  void init() {
    _sub = Connectivity().onConnectivityChanged.listen((result) {
      final wasOnline = isOnline;
      _status = result == ConnectivityResult.none
        ? ConnectionStatus.offline
        : ConnectionStatus.online;

      if (wasOnline != isOnline) notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
