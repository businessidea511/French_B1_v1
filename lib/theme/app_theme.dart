import 'package:flutter/material.dart';

class AppTheme {
  // Premium Color Palette
  // Premium Color Palette - More vibrant and comfortable
  static const Color background = Color(0xFF0F172A); // Deep Slate/Navy
  static const Color surface = Color(0xFF1E293B);    // Lighter Slate for cards
  static const Color primary = Color(0xFF818CF8);    // Softer Indigo
  static const Color secondary = Color(0xFFF472B6);  // Softer Pink
  static const Color accent = Color(0xFFA78BFA);     // Softer Purple
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF87171);
  static const Color surfaceLight = Color(0xFF334155);

  // Text Colors - Higher contrast
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color textTertiary = Color(0xFF94A3B8);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color(0x1AFFFFFF), // white10
      Color(0x0DFFFFFF), // white05
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient studyFrontGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient studyBackGradient = LinearGradient(
    colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glassmorphism Decoration
  static BoxDecoration glassDecoration({double blur = 10, double opacity = 0.05}) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
    );
  }

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    fontFamily: 'Outfit', // We'll ensure this is in pubspec or use fallback
    
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        letterSpacing: 0.5,
      ),
    ),
    
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 42,
        fontWeight: FontWeight.w900,
        color: textPrimary,
        letterSpacing: -1,
      ),
      displayMedium: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 18,
        color: textPrimary,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        color: textSecondary,
        height: 1.5,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primary, width: 1),
      ),
    ),
  );
}
