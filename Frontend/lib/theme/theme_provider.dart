import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;

  ThemeProvider() {
    _load();
  }

  void _load() async {
    final isDark = await PreferencesService.isDarkMode();
    _mode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void toggle(bool isDark) {
    _mode = isDark ? ThemeMode.dark : ThemeMode.light;
    PreferencesService.setDarkMode(isDark);
    notifyListeners();
  }
}
