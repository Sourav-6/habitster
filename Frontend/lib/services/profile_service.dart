import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  static const _nameKey = "profile_name";
  static const _emailKey = "profile_email";
  static const _imageKey = "profile_image";
  static const _themeKey = "profile_theme_dark";
  static const _langKey = "profile_language";

  // ---------- Name ----------
  static Future<String> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey) ?? "Your Name";
  }

  static Future<void> setName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
  }

  // ---------- Email ----------
  static Future<String> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey) ?? "user@email.com";
  }

  static Future<void> setEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
  }

  // ---------- Profile Image ----------
  static Future<String?> getImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_imageKey);
  }

  static Future<void> setImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_imageKey, path);
  }

  // ---------- Theme ----------
  static Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? false;
  }

  static Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, value);
  }

  // ---------- Language ----------
  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_langKey) ?? "English";
  }

  static Future<void> setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, lang);
  }
}
