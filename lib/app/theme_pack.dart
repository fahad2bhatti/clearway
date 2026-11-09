import 'package:flutter/material.dart';

/// Visual identity for a yard theme. Gameplay data never depends on this pack.
final class ThemePack {
  const ThemePack({
    required this.id,
    required this.name,
    required this.asphalt,
    required this.yardSurface,
    required this.gridLine,
    required this.ivory,
    required this.panel,
    required this.panelActive,
    required this.textMuted,
    required this.iconDisabled,
    required this.textDisabled,
    required this.accent,
    required this.floralMagenta,
    required this.emerald,
    required this.turquoise,
    required this.coral,
    required this.showFloralMotifs,
    required this.vehicleNoun,
    required this.emptyYardMessage,
  });

  final String id;
  final String name;
  final Color asphalt;
  final Color yardSurface;
  final Color gridLine;
  final Color ivory;

  /// Dialog and button surfaces, their selected state, and muted or
  /// disabled foregrounds.
  final Color panel;
  final Color panelActive;
  final Color textMuted;
  final Color iconDisabled;
  final Color textDisabled;
  final Color accent;
  final Color floralMagenta;
  final Color emerald;
  final Color turquoise;
  final Color coral;
  final bool showFloralMotifs;
  final String vehicleNoun;
  final String emptyYardMessage;

  /// Board and HUD palette, matching [OnboardingTheme]. [accent] stays amber
  /// because the board draws it as the traffic-cone colour.
  static const truckArt = ThemePack(
    id: 'truck_art_yard',
    name: 'Truck-art yard',
    asphalt: Color(0xff0c0c0e),
    yardSurface: Color(0xff151518),
    gridLine: Color(0xff26262b),
    ivory: Color(0xfff4f4f0),
    panel: Color(0xff151518),
    panelActive: Color(0xff28284b),
    textMuted: Color(0xff8e8e96),
    iconDisabled: Color(0xff4a4a52),
    textDisabled: Color(0xff5e5e66),
    accent: Color(0xffffb020),
    floralMagenta: Color(0xffff5c8d),
    emerald: Color(0xff61c69a),
    turquoise: Color(0xff6ee7d8),
    coral: Color(0xffff5b3a),
    showFloralMotifs: true,
    vehicleNoun: 'vehicle',
    emptyYardMessage: 'All clear!',
  );
}
