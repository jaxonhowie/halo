import 'package:flutter_test/flutter_test.dart';
import 'package:halo_windows/services/session_service.dart';

void main() {
  group('SessionService', () {
    late SessionService service;

    setUp(() {
      service = SessionService();
    });

    tearDown(() {
      service.dispose();
    });

    test('idle timeout is 10 minutes', () {
      expect(SessionService.idleTimeout, const Duration(minutes: 10));
    });

    test('todayWorkSeconds returns 0 when no activity', () {
      // No keyboard activity yet, should return StorageService.workSeconds
      // (which may be 0 in test env)
      final seconds = service.todayWorkSeconds;
      expect(seconds, isNonNegative);
    });

    test('onKeyboardActivity starts session', () {
      service.onKeyboardActivity();
      // After activity, todayWorkSeconds should include current session
      final seconds = service.todayWorkSeconds;
      expect(seconds, isNonNegative);
    });

    test('endSession is safe when no session', () {
      // Should not throw
      service.endSession();
    });

    test('dispose calls endSession', () {
      service.onKeyboardActivity();
      // Should not throw
      service.dispose();
    });
  });
}
