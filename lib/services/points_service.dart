import 'package:shared_preferences/shared_preferences.dart';

class PointsService {
  static const _keyTotal = 'points_total';
  static const _keyWeekly = 'points_weekly';

  Future<int> addPoints(int value) async {
    final prefs = await SharedPreferences.getInstance();
    final total = prefs.getInt(_keyTotal) ?? 0;
    final weekly = prefs.getInt(_keyWeekly) ?? 0;
    await prefs.setInt(_keyTotal, total + value);
    await prefs.setInt(_keyWeekly, weekly + value);
    return total + value;
  }

  Future<Map<String, int>> getPoints() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'total': prefs.getInt(_keyTotal) ?? 0,
      'weekly': prefs.getInt(_keyWeekly) ?? 0,
    };
  }

  Future<void> resetWeekly() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyWeekly, 0);
  }
}