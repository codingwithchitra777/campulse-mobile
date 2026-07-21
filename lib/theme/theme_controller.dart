import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the active [ThemeMode] and persists it. Dark is the default (matches
/// the web app). Listen to it above [MaterialApp] to rebuild on toggle.
class ThemeController extends ChangeNotifier {
  static final ThemeController instance = ThemeController._();
  ThemeController._();

  static const _prefsKey = 'theme_mode';

  ThemeMode _mode = ThemeMode.dark;
  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    _mode = stored == 'light' ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  Future<void> toggle() => setDark(!isDark);

  Future<void> setDark(bool dark) async {
    _mode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, dark ? 'dark' : 'light');
  }
}
