import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'colors.dart';

class ThemeService {
  static const String _themeKey = 'app_theme_color';

  static Future<Color> loadThemeColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt(_themeKey);
    if (colorValue == null) return AppColors.primary;
    return Color(colorValue);
  }

  static Future<void> saveThemeColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, color.toARGB32());
  }
}
