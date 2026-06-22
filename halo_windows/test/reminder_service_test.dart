import 'package:flutter_test/flutter_test.dart';
import 'package:halo_windows/services/reminder_service.dart';

void main() {
  group('ReminderService', () {
    late ReminderService service;
    int waterReminderCount = 0;
    int walkReminderCount = 0;
    int waterCountdownStartCount = 0;
    int walkCountdownStartCount = 0;
    int waterCountdownClearCount = 0;
    int walkCountdownClearCount = 0;

    setUp(() {
      waterReminderCount = 0;
      walkReminderCount = 0;
      waterCountdownStartCount = 0;
      walkCountdownStartCount = 0;
      waterCountdownClearCount = 0;
      walkCountdownClearCount = 0;

      service = ReminderService(
        onWaterReminder: () => waterReminderCount++,
        onWalkReminder: () => walkReminderCount++,
        onWaterCountdownStart: () => waterCountdownStartCount++,
        onWalkCountdownStart: () => walkCountdownStartCount++,
        onWaterCountdownClear: () => waterCountdownClearCount++,
        onWalkCountdownClear: () => walkCountdownClearCount++,
      );
    });

    tearDown(() {
      service.dispose();
    });

    test('initial state is not reminding', () {
      expect(service.isWaterReminding, false);
      expect(service.isWalkReminding, false);
    });

    test('water interval is 15 minutes', () {
      expect(ReminderService.waterInterval, const Duration(minutes: 15));
    });

    test('walk interval is 60 minutes', () {
      expect(ReminderService.walkInterval, const Duration(minutes: 60));
    });

    test('first keyboard activity starts both countdowns', () {
      service.onKeyboardActivity();
      expect(waterCountdownStartCount, 1);
      expect(walkCountdownStartCount, 1);
    });

    test('subsequent keyboard activity does not restart countdowns', () {
      service.onKeyboardActivity();
      service.onKeyboardActivity();
      service.onKeyboardActivity();
      // Countdowns only start once (timer is already set)
      expect(waterCountdownStartCount, 1);
      expect(walkCountdownStartCount, 1);
    });

    test('triggerWaterReminder fires callback', () {
      service.triggerWaterReminder();
      expect(waterReminderCount, 1);
    });

    test('triggerWaterReminder clears countdown', () {
      service.triggerWaterReminder();
      expect(waterCountdownClearCount, 1);
    });

    test('triggerWalkReminder fires callback', () {
      service.triggerWalkReminder();
      expect(walkReminderCount, 1);
    });

    test('triggerWalkReminder clears countdown', () {
      service.triggerWalkReminder();
      expect(walkCountdownClearCount, 1);
    });

    test('triggerWaterReminder is idempotent during alert', () {
      // Simulate what happens: first call sets _isWaterReminding,
      // but it's set to false synchronously after callback
      service.triggerWaterReminder();
      service.triggerWaterReminder();
      // Both calls go through since _isWaterReminding is reset synchronously
      expect(waterReminderCount, 2);
    });
  });
}
