import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _prefThemeKey = 'theme_is_dark';
  static const String _prefElderlyKey = 'accessibility_elderly_mode';

  bool _isDark = false;
  bool _isElderlyMode = false;

  bool get isDark => _isDark;
  bool get isElderlyMode => _isElderlyMode;

  ThemeProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDark = prefs.getBool(_prefThemeKey) ?? false;
      _isElderlyMode = prefs.getBool(_prefElderlyKey) ?? false;
      notifyListeners();
    } catch (e) {
      // ignore
    }
  }

  Future<void> toggleTheme(bool value) async {
    _isDark = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefThemeKey, value);
    } catch (e) {
      // ignore
    }
  }

  Future<void> toggleElderlyMode(bool value) async {
    _isElderlyMode = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefElderlyKey, value);
    } catch (e) {
      // ignore
    }
  }

  double get fontSizeMultiplier => _isElderlyMode ? 1.30 : 1.0;
  
  double getScale(double originalSize) => originalSize * fontSizeMultiplier;

  ThemeData get currentTheme {
    final primaryColor = _isElderlyMode 
        ? (_isDark ? const Color(0xFF90CAF9) : const Color(0xFF0D47A1)) 
        : const Color(0xFF2B5C8F);
    
    final accentColor = _isElderlyMode 
        ? (_isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100)) 
        : const Color(0xFF10B981);

    final textTheme = TextTheme(
      displayLarge: TextStyle(fontSize: getScale(30), fontWeight: FontWeight.bold),
      titleLarge: TextStyle(fontSize: getScale(20), fontWeight: FontWeight.bold),
      titleMedium: TextStyle(fontSize: getScale(18), fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: getScale(16)),
      bodyMedium: TextStyle(fontSize: getScale(14)),
      labelLarge: TextStyle(fontSize: getScale(16), fontWeight: FontWeight.bold),
    );

    if (_isDark) {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: primaryColor,
          secondary: accentColor,
          surface: const Color(0xFF1E1E1E),
          background: const Color(0xFF121212),
          error: const Color(0xFFEF5350),
        ),
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          titleTextStyle: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF252525),
          elevation: _isElderlyMode ? 6 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: _isElderlyMode 
                ? BorderSide(color: primaryColor, width: 2.0) 
                : BorderSide.none,
          ),
        ),
      );
    } else {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: primaryColor,
          secondary: accentColor,
          surface: Colors.white,
          background: const Color(0xFFF1F5F9),
          error: const Color(0xFFD32F2F),
        ),
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          titleTextStyle: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: _isElderlyMode ? 6 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: _isElderlyMode 
                ? BorderSide(color: primaryColor, width: 2.5) 
                : BorderSide.none,
          ),
        ),
      );
    }
  }
}
