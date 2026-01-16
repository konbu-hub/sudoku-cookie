import 'package:flutter/material.dart';

/// アプリのテーマ定義
class AppTheme {
  // カラーパレット
  static const Color darkBackground = Color(0xFF1a1a2e);
  static const Color darkPanel = Color(0xFF16213e);
  static const Color accentColor = Color(0xFF6366f1);
  static const Color accentGlow = Color(0xFFa855f7);
  static const Color textPrimary = Color(0xFFe8e8e8);
  static const Color textSecondary = Color(0xFFa0a0a0);
  static const Color errorColor = Color(0xFFef4444);
  static const Color successColor = Color(0xFF10b981);

  static const Color lightBackground = Color(0xFFf5f5f5);
  static const Color lightPanel = Color(0xFFffffff);
  static const Color lightTextPrimary = Color(0xFF1a1a2e);
  static const Color lightTextSecondary = Color(0xFF6b7280);

  /// ダークテーマ
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: accentColor,
      colorScheme: const ColorScheme.dark(
        primary: accentColor,
        secondary: accentGlow,
        surface: darkPanel,
        error: errorColor,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          fontFamily: 'Outfit',
        ),
        displayMedium: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontFamily: 'Outfit',
        ),
        titleLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontFamily: 'Outfit',
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimary,
          fontFamily: 'Outfit',
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondary,
          fontFamily: 'Outfit',
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkPanel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  /// ライトテーマ
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      primaryColor: accentColor,
      colorScheme: const ColorScheme.light(
        primary: accentColor,
        secondary: accentGlow,
        surface: lightPanel,
        error: errorColor,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w800,
          color: lightTextPrimary,
          fontFamily: 'Outfit',
        ),
        displayMedium: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
          fontFamily: 'Outfit',
        ),
        titleLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
          fontFamily: 'Outfit',
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: lightTextPrimary,
          fontFamily: 'Outfit',
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: lightTextSecondary,
          fontFamily: 'Outfit',
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightPanel,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
