import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode;

  ThemeMode get mode => _mode;

  ThemeProvider({ThemeMode initialMode = ThemeMode.light}) : _mode = initialMode;

  void toggle(bool isDark) {
    _mode = isDark ? ThemeMode.dark : ThemeMode.light;
    PreferencesService.setDarkMode(isDark);
    notifyListeners();
  }
}
