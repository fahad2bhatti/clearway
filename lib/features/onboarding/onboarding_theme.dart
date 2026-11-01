import 'package:flutter/material.dart';

/// Shared visual tokens for the onboarding flow (Figma-aligned).
abstract final class OnboardingTheme {
  static const Color bgTop = Color(0xFF120D2B);
  static const Color bgBottom = Color(0xFF2B1650);
  static const Color cream = Color(0xFFFFF4DC);
  static const Color gold = Color(0xFFFFB627);
  static const Color goldDark = Color(0xFFE08A00);
  static const Color teal = Color(0xFF22C7B0);
  static const Color muted = Color(0xFFB8AEDB);
  static const Color deepPurple = Color(0xFF1B1033);
  static const Color cardPurple = Color(0xFF3A2F8F);
  static const Color cardPurpleDark = Color(0xFF1B1440);

  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgTop, bgBottom],
  );

  static const LinearGradient logoTile = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFC94D), Color(0xFFF28C00)],
  );

  static BoxDecoration primaryButton = BoxDecoration(
    color: gold,
    borderRadius: BorderRadius.circular(28),
    boxShadow: const [
      BoxShadow(
        color: goldDark,
        offset: Offset(0, 5),
        blurRadius: 0,
      ),
    ],
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
}
