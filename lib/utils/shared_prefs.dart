import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  // --- Configuración de tema oscuro (ya existente) ---
  static Future<void> setDarkMode(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
  }

  static Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isDarkMode') ?? true; // Default: true (modo oscuro)
  }

  // --- Nuevos métodos para notificaciones ---
  static const _keyNotificationsEnabled = 'notifications_enabled';

  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, enabled);
  }

  static Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ??
        true; // Default: true (activadas)
  }
}
