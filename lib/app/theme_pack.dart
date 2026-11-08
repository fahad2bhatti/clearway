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

  static const truckArt = ThemePack(
    id: 'truck_art_yard',
    name: 'Truck-art yard',
    asphalt: Color(0xff182329),
    yardSurface: Color(0xff202f35),
    gridLine: Color(0xff3d5154),
    ivory: Color(0xfffff3d8),
    panel: Color(0xff25343a),
    panelActive: Color(0xff38554f),
    textMuted: Color(0xffc6d2ca),
    iconDisabled: Color(0xff69777a),
    textDisabled: Color(0xff758386),
    accent: Color(0xffffb347),
    floralMagenta: Color(0xffed6ca7),
    emerald: Color(0xff61c69a),
    turquoise: Color(0xff4ecac1),
    coral: Color(0xffff796c),
    showFloralMotifs: true,
    vehicleNoun: 'vehicle',
    emptyYardMessage: 'All clear!',
  );

  /// Navy + mint "arrow night" look shared by Home, Shop and Settings. The game
  /// board keeps using [truckArt].
  static const arrowNight = ThemePack(
    // theme-v2
    id: 'arrow_night',
    name: 'Arrow night',
    asphalt: Color(0xff0b1020),
    yardSurface: Color(0xff111831),
    gridLine: Color(0xff252e4a),
    ivory: Color(0xfff2f4fa),
    panel: Color(0xff151d38),
    panelActive: Color(0xff1e2a4d),
    textMuted: Color(0xff9aa3bf),
    iconDisabled: Color(0xff5a6483),
    textDisabled: Color(0xff6b7595),
    accent: Color(0xff6ee7c8),
    floralMagenta: Color(0xffff5c8d),
    emerald: Color(0xff4ade80),
    turquoise: Color(0xff6ee7c8),
    coral: Color(0xffff796c),
    showFloralMotifs: false,
    vehicleNoun: 'arrow',
    emptyYardMessage: 'All clear!',
  );
}
