import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the active [Locale] (en/km) and persists it, so the language switch
/// can live in the Account hub while the nav shell stays stateless about it.
class LocaleController extends ChangeNotifier {
  static final LocaleController instance = LocaleController._();
  LocaleController._();

  static const _prefsKey = 'lang';
  static const supported = ['en', 'km'];

  Locale _locale = const Locale('en');
  Locale get locale => _locale;
  String get code => _locale.languageCode;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    if (stored != null && supported.contains(stored)) {
      _locale = Locale(stored);
      notifyListeners();
    }
  }

  Future<void> setCode(String code) async {
    if (!supported.contains(code) || code == _locale.languageCode) return;
    _locale = Locale(code);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, code);
  }
}
