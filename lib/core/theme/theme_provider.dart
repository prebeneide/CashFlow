import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _useSystemMode = true;
  
  bool get isDarkMode => _isDarkMode;
  bool get useSystemMode => _useSystemMode;

  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _useSystemMode = prefs.getBool('use_system_mode') ?? true;
    _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    notifyListeners();
  }

  Future<void> setSystemMode(bool value) async {
    _useSystemMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_system_mode', value);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    _useSystemMode = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', value);
    await prefs.setBool('use_system_mode', false);
    notifyListeners();
  }

  ThemeData getTheme(BuildContext context) {
    if (_useSystemMode) {
      final brightness = MediaQuery.of(context).platformBrightness;
      return brightness == Brightness.dark
          ? AppTheme.darkTheme()
          : AppTheme.lightTheme();
    }
    return _isDarkMode ? AppTheme.darkTheme() : AppTheme.lightTheme();
  }
}

