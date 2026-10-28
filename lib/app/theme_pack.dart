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
    required this.vehicleColors,
    required this.showFloralMotifs,
    required this.vehicleNoun,
    required this.emptyYardMessage,
    this.backdropAsset,
    this.successSoundAsset,
    this.blockedSoundAsset,
    this.musicAsset,
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
  final List<Color> vehicleColors;
  final bool showFloralMotifs;
  final String vehicleNoun;
  final String emptyYardMessage;
  final String? backdropAsset;
  final String? successSoundAsset;
  final String? blockedSoundAsset;
  final String? musicAsset;

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
    vehicleColors: [
      Color(0xffffb347),
      Color(0xffed6ca7),
      Color(0xff61c69a),
      Color(0xff4ecac1),
      Color(0xffff796c),
    ],
    showFloralMotifs: true,
    vehicleNoun: 'vehicle',
    emptyYardMessage: 'All clear!',
    successSoundAsset: 'audio/horn_clear.mp3',
    blockedSoundAsset: 'audio/horn_bump.mp3',
    musicAsset: 'audio/yard_lofi.mp3',
  );
}
