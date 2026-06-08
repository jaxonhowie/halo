import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // Window position
  static double? getWindowX() => _prefs?.getDouble('window_x');
  static double? getWindowY() => _prefs?.getDouble('window_y');
  static Future<void> setWindowPosition(double x, double y) async {
    await _prefs?.setDouble('window_x', x);
    await _prefs?.setDouble('window_y', y);
  }

  // Water count (daily reset)
  static int get waterCount {
    final savedDate = _prefs?.getString('water_date') ?? '';
    final today = _todayString();
    if (savedDate != today) {
      _prefs?.setString('water_date', today);
      _prefs?.setInt('water_count', 0);
      return 0;
    }
    return _prefs?.getInt('water_count') ?? 0;
  }

  static Future<void> incrementWater() async {
    final savedDate = _prefs?.getString('water_date') ?? '';
    final today = _todayString();
    final base = (savedDate == today) ? (_prefs?.getInt('water_count') ?? 0) : 0;
    await _prefs?.setString('water_date', today);
    await _prefs?.setInt('water_count', base + 1);
  }

  // Walk count (daily reset)
  static int get walkCount {
    final savedDate = _prefs?.getString('walk_date') ?? '';
    final today = _todayString();
    if (savedDate != today) {
      _prefs?.setString('walk_date', today);
      _prefs?.setInt('walk_count', 0);
      return 0;
    }
    return _prefs?.getInt('walk_count') ?? 0;
  }

  static Future<void> incrementWalk() async {
    final savedDate = _prefs?.getString('walk_date') ?? '';
    final today = _todayString();
    final base = (savedDate == today) ? (_prefs?.getInt('walk_count') ?? 0) : 0;
    await _prefs?.setString('walk_date', today);
    await _prefs?.setInt('walk_count', base + 1);
  }

  // Work seconds (daily reset)
  static int get workSeconds {
    final savedDate = _prefs?.getString('work_date') ?? '';
    final today = _todayString();
    if (savedDate != today) {
      _prefs?.setString('work_date', today);
      _prefs?.setInt('work_seconds', 0);
      return 0;
    }
    return _prefs?.getInt('work_seconds') ?? 0;
  }

  static Future<void> addWorkSeconds(int seconds) async {
    final savedDate = _prefs?.getString('work_date') ?? '';
    final today = _todayString();
    final base = (savedDate == today) ? (_prefs?.getInt('work_seconds') ?? 0) : 0;
    await _prefs?.setString('work_date', today);
    await _prefs?.setInt('work_seconds', base + seconds);
  }
}
