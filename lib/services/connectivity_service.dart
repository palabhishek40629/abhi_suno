import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal() {
    _init();
  }

  bool _isOnline = true;
  int _consecutiveFailures = 0;
  Timer? _timer;

  bool get isOnline => _isOnline;

  void _init() {
    checkConnection();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => checkConnection());
  }

  Future<void> checkConnection() async {
    bool foundOnline = false;

    // Fast check across multiple trusted DNS endpoints to avoid false alarms
    for (final host in ['google.com', 'cloudflare.com', 'jiosaavn.com']) {
      try {
        final result = await InternetAddress.lookup(host)
            .timeout(const Duration(seconds: 2));
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          foundOnline = true;
          break;
        }
      } catch (_) {}
    }

    if (foundOnline) {
      _consecutiveFailures = 0;
      if (!_isOnline) {
        _isOnline = true;
        notifyListeners();
      }
    } else {
      _consecutiveFailures++;
      // Only declare offline after 2 consecutive failed multi-host checks (stops flickering orange banner)
      if (_consecutiveFailures >= 2 && _isOnline) {
        _isOnline = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
