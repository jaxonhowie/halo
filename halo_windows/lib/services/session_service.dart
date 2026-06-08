import 'dart:async';
import 'storage_service.dart';

class SessionService {
  DateTime? _sessionStart;
  DateTime? _lastKeyboardActivity;
  Timer? _idleTimer;
  static const idleTimeout = Duration(minutes: 10);

  void onKeyboardActivity() {
    _lastKeyboardActivity = DateTime.now();
    _sessionStart ??= DateTime.now();
    _idleTimer?.cancel();
    _idleTimer = Timer(idleTimeout, endSession);
  }

  int get todayWorkSeconds {
    int saved = StorageService.workSeconds;
    if (_sessionStart != null && _lastKeyboardActivity != null) {
      saved += _lastKeyboardActivity!.difference(_sessionStart!).inSeconds;
    }
    return saved;
  }

  void endSession() {
    if (_sessionStart != null && _lastKeyboardActivity != null) {
      final elapsed = _lastKeyboardActivity!.difference(_sessionStart!).inSeconds;
      StorageService.addWorkSeconds(elapsed);
    }
    _sessionStart = null;
    _idleTimer = null;
  }

  void dispose() {
    endSession();
    _idleTimer?.cancel();
  }
}
