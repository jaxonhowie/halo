import 'dart:async';
import 'storage_service.dart';

class ReminderService {
  Timer? _waterTimer;
  Timer? _walkTimer;
  bool _isWaterReminding = false;
  bool _isWalkReminding = false;

  static const waterInterval = Duration(minutes: 15);
  static const walkInterval = Duration(minutes: 60);

  final void Function() onWaterReminder;
  final void Function() onWalkReminder;
  final void Function() onWaterCountdownStart;
  final void Function() onWalkCountdownStart;
  final void Function() onWaterCountdownClear;
  final void Function() onWalkCountdownClear;

  ReminderService({
    required this.onWaterReminder,
    required this.onWalkReminder,
    required this.onWaterCountdownStart,
    required this.onWalkCountdownStart,
    required this.onWaterCountdownClear,
    required this.onWalkCountdownClear,
  });

  bool get isWaterReminding => _isWaterReminding;
  bool get isWalkReminding => _isWalkReminding;

  void onKeyboardActivity() {
    if (!_isWalkReminding && _walkTimer == null) {
      _walkTimer = Timer(walkInterval, () {
        _walkTimer = null;
        triggerWalkReminder();
      });
      onWalkCountdownStart();
    }
    if (!_isWaterReminding && _waterTimer == null) {
      _waterTimer = Timer(waterInterval, () {
        _waterTimer = null;
        triggerWaterReminder();
      });
      onWaterCountdownStart();
    }
  }

  void triggerWaterReminder() {
    if (_isWaterReminding) return;
    _isWaterReminding = true;
    _waterTimer?.cancel();
    _waterTimer = null;
    onWaterCountdownClear();
    onWaterReminder();
    StorageService.incrementWater();
    _isWaterReminding = false;
  }

  void triggerWalkReminder() {
    if (_isWalkReminding) return;
    _isWalkReminding = true;
    _walkTimer?.cancel();
    _walkTimer = null;
    onWalkCountdownClear();
    onWalkReminder();
    StorageService.incrementWalk();
    _isWalkReminding = false;
  }

  void dispose() {
    _waterTimer?.cancel();
    _walkTimer?.cancel();
  }
}
