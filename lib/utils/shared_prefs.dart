import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  static Future<void> setDarkMode(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
  }

  static Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isDarkMode') ??
        true; // Por defecto, se establece en true (modo oscuro).
  }
}
