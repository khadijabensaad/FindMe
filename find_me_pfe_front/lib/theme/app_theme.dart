import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// FINDME — design tokens.
/// The palette of the original app (cream #FDF1E1, orange #DF9A4F, brown #965D1A)
/// refined with a deep espresso for strong actions and soft warm surfaces.
class AppColors {
  static const ink = Color(0xFF2E2118); // espresso: strong buttons, user bubbles, titles
  static const cream = Color(0xFFFDF1E1); // original FINDME background
  static const camel = Color(0xFFDF9A4F); // original FINDME orange (accents, center button)
  static const brown = Color(0xFF965D1A); // original FINDME brown (titles, active icons)
  static const brownText = Color(0xFF8F5622); // accessible brown for small text on cream
  static const rose = Color(0xFFD98C7A); // soft terracotta (Trending)
  static const white = Color(0xFFFFFFFF);

  static const card = Color(0xFFFFF9F1); // warm card surface
  static const sand = Color(0xFFF0DFC6); // borders, skeletons, tracks
  static const peach = Color(0xFFF8E3C8); // bot bubbles, soft highlights
  static const muted = Color(0xFF7D6855); // secondary text
  static const success = Color(0xFF4E8A64);

  static const caramel = LinearGradient(
    colors: [Color(0xFFEBB16B), Color(0xFFDF9A4F), Color(0xFFB8732F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const espresso = LinearGradient(
    colors: [Color(0xFF4A3322), Color(0xFF2E2118)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static List<BoxShadow> softShadow = [
    BoxShadow(color: const Color(0xFF965D1A).withOpacity(0.10), blurRadius: 18, offset: const Offset(0, 8)),
  ];

  // dark mode
  static const night = Color(0xFF17110C);
  static const nightCard = Color(0xFF241A13);
  static const nightLine = Color(0xFF3A2C21);
}

class AppRadius {
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

/// Context helpers so widgets work in light and dark mode.
extension FindMeTheme on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bg => isDark ? AppColors.night : AppColors.cream;
  Color get card => isDark ? AppColors.nightCard : AppColors.card;
  Color get line => isDark ? AppColors.nightLine : AppColors.sand;
  Color get fg => isDark ? AppColors.cream : AppColors.ink;
  Color get fgMuted => isDark ? const Color(0xFFBFAE9C) : AppColors.muted;
  Color get accentText => isDark ? AppColors.camel : AppColors.brownText;
  TextTheme get text => Theme.of(this).textTheme;
}

class AppTheme {
  static TextStyle display(double size, {Color? color, FontWeight weight = FontWeight.w600, double? height}) =>
      GoogleFonts.playfairDisplay(fontSize: size, fontWeight: weight, color: color, height: height, letterSpacing: -0.3);

  static TextTheme _textTheme(Color fg, Color muted) {
    TextStyle p(double size, FontWeight w, {Color? c, double ls = 0}) =>
        TextStyle(fontFamily: 'Poppins', fontSize: size, fontWeight: w, color: c ?? fg, letterSpacing: ls);
    return TextTheme(
      displaySmall: display(34, color: fg),
      headlineMedium: display(28, color: fg),
      headlineSmall: display(24, color: fg),
      titleLarge: p(20, FontWeight.w600),
      titleMedium: p(16, FontWeight.w600),
      titleSmall: p(14, FontWeight.w600),
      bodyLarge: p(15, FontWeight.w400),
      bodyMedium: p(14, FontWeight.w400),
      bodySmall: p(12, FontWeight.w400, c: muted),
      labelLarge: p(14, FontWeight.w600, ls: 0.2),
      labelMedium: p(12, FontWeight.w600, ls: 0.3),
      labelSmall: p(11, FontWeight.w500, c: muted, ls: 0.4),
    );
  }

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.camel,
      brightness: Brightness.light,
      primary: AppColors.ink,
      onPrimary: AppColors.cream,
      secondary: AppColors.camel,
      onSecondary: AppColors.white,
      tertiary: AppColors.rose,
      surface: AppColors.card,
      onSurface: AppColors.ink,
      error: const Color(0xFFB3261E),
    );
    return _base(scheme, AppColors.cream, AppColors.ink, AppColors.muted, AppColors.sand);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.camel,
      brightness: Brightness.dark,
      primary: AppColors.cream,
      onPrimary: AppColors.ink,
      secondary: AppColors.camel,
      onSecondary: AppColors.ink,
      tertiary: AppColors.rose,
      surface: AppColors.nightCard,
      onSurface: AppColors.cream,
    );
    return _base(scheme, AppColors.night, AppColors.cream, const Color(0xFFBFAE9C), AppColors.nightLine);
  }

  static ThemeData _base(ColorScheme scheme, Color bg, Color fg, Color muted, Color line) {
    final text = _textTheme(fg, muted);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: scheme.brightness,
      scaffoldBackgroundColor: bg,
      fontFamily: 'Poppins',
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: display(22, color: fg),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        hintStyle: TextStyle(fontFamily: 'Poppins', color: muted, fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.xl), borderSide: BorderSide(color: line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.xl), borderSide: BorderSide(color: line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.xl), borderSide: const BorderSide(color: AppColors.camel, width: 1.4)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
          textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          side: BorderSide(color: line, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
          textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        selectedColor: AppColors.camel,
        secondarySelectedColor: AppColors.camel,
        checkmarkColor: AppColors.ink,
        side: BorderSide(color: line),
        labelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: fg),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(fontFamily: 'Poppins', color: AppColors.cream),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      dividerColor: line,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}

/// Light / dark mode, persisted.
class ThemeController {
  ThemeController._();
  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.light);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    mode.value = (prefs.getBool('darkMode') ?? false) ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> toggle() async {
    mode.value = mode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', mode.value == ThemeMode.dark);
  }
}
