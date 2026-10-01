import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/motion.dart';

/// The "Soleil" palette: coral, mint, sunny yellow and sky blue on warm
/// neutrals. Two modes that are easy on the eyes: no pure white, no pure black.
class _Palette {
  final Color background, surface, surfaceLight, textPrimary, textSecondary, textTertiary;
  final Color primary, secondary, accent, success, warning, error, sun;

  const _Palette({
    required this.background,
    required this.surface,
    required this.surfaceLight,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.success,
    required this.warning,
    required this.error,
    required this.sun,
  });
}

const _light = _Palette(
  background: Color(0xFFFBF7F0), // warm cream
  surface: Color(0xFFFFFDF9),
  surfaceLight: Color(0xFFF1EBE1),
  textPrimary: Color(0xFF2E2B3A), // ink, not black
  textSecondary: Color(0xFF5B5668),
  textTertiary: Color(0xFF8A8494),
  primary: Color(0xFFE0604A), // coral
  secondary: Color(0xFFD9578A), // raspberry
  accent: Color(0xFF3D8BE0), // sky blue
  success: Color(0xFF23A07F), // mint
  warning: Color(0xFFC98A0E), // amber, readable on cream
  error: Color(0xFFD64545),
  sun: Color(0xFFF7B733), // sunny yellow (decoration)
);

const _dark = _Palette(
  background: Color(0xFF1C1F2B), // soft night, not black
  surface: Color(0xFF262A38),
  surfaceLight: Color(0xFF323748),
  textPrimary: Color(0xFFECE8E1), // warm off-white, not pure white
  textSecondary: Color(0xFFC3BEB5),
  textTertiary: Color(0xFF918C99),
  primary: Color(0xFFF07C68),
  secondary: Color(0xFFF08AAE),
  accent: Color(0xFF6FB1FF),
  success: Color(0xFF4CC9A6),
  warning: Color(0xFFF5C04E),
  error: Color(0xFFF07575),
  sun: Color(0xFFF7C04E),
);

class AppTheme {
  /// Which mode the colours below belong to. Set by [ThemeController].
  static bool isDark = true;
  static _Palette get _p => isDark ? _dark : _light;

  static Color get background => _p.background;
  static Color get surface => _p.surface;
  static Color get surfaceLight => _p.surfaceLight;
  static Color get textPrimary => _p.textPrimary;
  static Color get textSecondary => _p.textSecondary;
  static Color get textTertiary => _p.textTertiary;
  static Color get primary => _p.primary;
  static Color get secondary => _p.secondary;
  static Color get accent => _p.accent;
  static Color get success => _p.success;
  static Color get warning => _p.warning;
  static Color get error => _p.error;
  static Color get sun => _p.sun;

  /// Noun genders: blue for masculine, pink for feminine (deeper in light mode for contrast).
  static Color get masculine => isDark ? const Color(0xFF7DB4F5) : const Color(0xFF2F6FCF);
  static Color get feminine => isDark ? const Color(0xFFF290BE) : const Color(0xFFC63F7C);

  /// Base colour for faint overlays and borders (light text in dark mode, ink in light mode).
  static Color get fg => _p.textPrimary;

  /// Text and icons on top of a coloured (coral, mint…) background.
  static const Color onColor = Color(0xFFFFFCF7);

  static LinearGradient get primaryGradient => LinearGradient(
        colors: [primary, sun],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get studyFrontGradient => LinearGradient(
        colors: [primary, const Color(0xFFF4A261)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get studyBackGradient => LinearGradient(
        colors: [success, accent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static ThemeData get darkTheme => _build(_dark, Brightness.dark);
  static ThemeData get lightTheme => _build(_light, Brightness.light);

  static ThemeData _build(_Palette p, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: p.primary,
      brightness: brightness,
      primary: p.primary,
      onPrimary: onColor,
      secondary: p.success,
      onSecondary: onColor,
      error: p.error,
      surface: p.surface,
      onSurface: p.textPrimary,
    );
    const transitions = Swing3DPageTransitionsBuilder();
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      // Pages are see-through: the animated AuroraBackground (main.dart) shows behind them.
      scaffoldBackgroundColor: Colors.transparent,
      fontFamily: 'Outfit',
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: transitions,
        TargetPlatform.iOS: transitions,
        TargetPlatform.windows: transitions,
        TargetPlatform.macOS: transitions,
        TargetPlatform.linux: transitions,
        TargetPlatform.fuchsia: transitions,
      }),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: p.surface, modalBackgroundColor: p.surface),
      dialogTheme: DialogThemeData(backgroundColor: p.surface),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.textPrimary,
        contentTextStyle: TextStyle(color: p.background, fontSize: 15),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background.withValues(alpha: 0.82),
        foregroundColor: p.textPrimary,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: p.textPrimary, letterSpacing: 0.3),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: p.textPrimary.withValues(alpha: 0.08)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceLight,
        selectedColor: p.primary,
        labelStyle: TextStyle(color: p.textPrimary),
        secondaryLabelStyle: const TextStyle(color: onColor),
        side: BorderSide(color: p.textPrimary.withValues(alpha: 0.1)),
      ),
      listTileTheme: ListTileThemeData(textColor: p.textPrimary, iconColor: p.textSecondary),
      iconTheme: IconThemeData(color: p.textSecondary),
      dividerColor: p.textPrimary.withValues(alpha: 0.08),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: p.textPrimary, letterSpacing: -1),
        displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: p.textPrimary),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: p.textPrimary),
        titleMedium: TextStyle(color: p.textPrimary),
        bodyLarge: TextStyle(fontSize: 18, color: p.textPrimary, height: 1.5),
        bodyMedium: TextStyle(fontSize: 16, color: p.textSecondary, height: 1.5),
        bodySmall: TextStyle(color: p.textTertiary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: onColor,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          side: BorderSide(color: p.textPrimary.withValues(alpha: 0.25)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: p.primary)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.textPrimary.withValues(alpha: 0.06),
        hintStyle: TextStyle(color: p.textTertiary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.primary, width: 1.5),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primary),
    );
  }
}

/// Auto (follow the device), light or dark. Saved on this device.
class ThemeController extends ChangeNotifier {
  static const _prefKey = 'theme_mode';
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  Future<void> load() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getString(_prefKey);
      _mode = ThemeMode.values.firstWhere((m) => m.name == saved, orElse: () => ThemeMode.system);
    } catch (_) {}
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    try {
      await (await SharedPreferences.getInstance()).setString(_prefKey, mode.name);
    } catch (_) {}
  }

  /// Whether the app should be dark, given the device brightness.
  bool resolveDark(Brightness platform) =>
      _mode == ThemeMode.dark || (_mode == ThemeMode.system && platform == Brightness.dark);
}
