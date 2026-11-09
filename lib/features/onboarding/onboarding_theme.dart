import 'package:flutter/material.dart';

/// Shared visual tokens for the onboarding flow (Figma-aligned).
abstract final class OnboardingTheme {
  // onboarding-theme-v3
  // Dark palette with a gold accent. Old names are kept so existing screens
  // compile.
  static const Color bgTop = Color(0xFF0C0C0E);
  static const Color bgBottom = Color(0xFF0C0C0E);
  static const Color surface = Color(0xFF151518);
  static const Color surfaceAlt = Color(0xFF111114);
  static const Color line = Color(0xFF26262B);
  static const Color accent = Color(0xFFD99400);
  // Text and icons on accent surfaces. Near-black: white on this gold is
  // only ~2.6:1, near-black is ~7.6:1.
  static const Color onAccent = Color(0xFF0C0C0E);
  static const Color hot = Color(0xFFFF5B3A);
  static const Color coin = Color(0xFFFFB020);
  static const Color cream = Color(0xFFF4F4F0);
  static const Color gold = accent;
  static const Color goldDark = Color(0xFFA86F00);
  static const Color teal = Color(0xFF6EE7D8);
  static const Color muted = Color(0xFF8E8E96);
  static const Color deepPurple = Color(0xFF0C0C0E);
  static const Color cardPurple = surface;
  static const Color cardPurpleDark = surfaceAlt;

  /// Condensed display font. Falls back to the default font until the
  /// font files are bundled.
  static const String displayFont = 'BarlowCondensed';

  static TextStyle display(
    double size, {
    Color color = cream,
    double letterSpacing = 0,
  }) => TextStyle(
    fontFamily: displayFont,
    fontSize: size,
    height: 1,
    fontWeight: FontWeight.w800,
    letterSpacing: letterSpacing,
    color: color,
  );

  static const TextStyle label = TextStyle(
    color: muted,
    fontSize: 11,
    letterSpacing: 1.6,
    fontWeight: FontWeight.w700,
  );

  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgTop, bgBottom],
  );

  static const LinearGradient logoTile = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gold, gold],
  );

  static BoxDecoration primaryButton = BoxDecoration(
    color: gold,
    borderRadius: BorderRadius.circular(28),
  );

  static const TextStyle wordmark = TextStyle(
    fontSize: 48,
    color: cream,
    letterSpacing: 2,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle tagline = TextStyle(
    fontSize: 18,
    color: gold,
    letterSpacing: 3,
    fontWeight: FontWeight.w700,
  );

  /// App-wide dark Material theme, so dialogs, sheets and snackbars match the
  /// redesigned screens without every call site restyling them.
  static final ThemeData materialTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgTop,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      onPrimary: onAccent,
      secondary: teal,
      surface: surface,
      onSurface: cream,
      error: hot,
    ),
    textTheme: ThemeData.dark().textTheme.apply(
      bodyColor: cream,
      displayColor: cream,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
        side: BorderSide(color: line),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: line,
      contentTextStyle: TextStyle(color: cream),
      actionTextColor: accent,
    ),
  );
}
