import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mengelola tema gelap/terang untuk seluruh aplikasi.
/// Pilihan disimpan di SharedPreferences sehingga bertahan antar sesi.
class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  static const _prefKey = 'theme_mode_dark';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_prefKey) ?? false;
    notifyListeners();
  }

  Future<void> setDark(bool value) async {
    _isDark = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
  }

  Future<void> toggle() => setDark(!_isDark);
}
