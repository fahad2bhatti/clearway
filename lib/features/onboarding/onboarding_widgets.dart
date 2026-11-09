import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'onboarding_theme.dart';

/// Flat dark page shell shared by every onboarding and tour screen.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(24, 16, 24, 28),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: OnboardingTheme.bgTop,
    body: SafeArea(
      child: Padding(padding: padding, child: child),
    ),
  );
}

/// Small spaced-out caption. Letter spacing breaks joined Urdu letters, so it
/// is dropped when the app is right-to-left.
class OnboardingLabel extends StatelessWidget {
  const OnboardingLabel(
    this.text, {
    super.key,
    this.size = 11,
    this.spacing = 1.6,
    this.color = OnboardingTheme.muted,
  });

  final String text;
  final double size;
  final double spacing;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Text(
      text.toUpperCase(),
      style: OnboardingTheme.label.copyWith(
        color: color,
        fontSize: size,
        letterSpacing: rtl ? 0 : spacing,
      ),
    );
  }
}

/// Small accent label that sits above a headline.
class OnboardingKicker extends StatelessWidget {
  const OnboardingKicker(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      OnboardingLabel(text, size: 12, color: OnboardingTheme.accent);
}

/// Full-width pill button. Pass a null [onTap] to show it disabled.
class OnboardingButton extends StatelessWidget {
  const OnboardingButton({
    super.key,
    required this.label,
    required this.onTap,
    this.busy = false,
    this.letterSpacing = 1.2,
  });

  final String label;
  final VoidCallback? onTap;
  final bool busy;

  /// Ignored (treated as 0) when the app is right-to-left.
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !busy;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      onTap: enabled ? onTap : null,
      excludeSemantics: true,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: enabled ? 1 : 0.45,
        child: Material(
          color: OnboardingTheme.accent,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onTap : null,
            child: SizedBox(
              height: 56,
              width: double.infinity,
              child: Center(
                child: busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: OnboardingTheme.onAccent,
                        ),
                      )
                    : Text(
                        label.toUpperCase(),
                        style: TextStyle(
                          color: OnboardingTheme.onAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing:
                              Directionality.of(context) == TextDirection.rtl
                              ? 0
                              : letterSpacing,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Thin segmented progress bar (one segment per tour step).
class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({
    super.key,
    required this.index,
    required this.total,
  });

  final int index;
  final int total;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < total; i++) ...[
        if (i > 0) const SizedBox(width: 6),
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 4,
            decoration: BoxDecoration(
              color: i <= index ? OnboardingTheme.accent : OnboardingTheme.line,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    ],
  );
}

/// Flat illustration of the game board: a grid of arrow tiles with one
/// highlighted. [step] picks what the highlight is showing:
/// -1 plain, 0 tap ring, 1 laser path, 2 coins + hint outline.
///
/// With [fill] the grid takes all the space it is given and adds rows to fit
/// (a fixed decorative pattern), instead of keeping the 6x4 tour layout.
class ArrowGridArt extends StatelessWidget {
  const ArrowGridArt({
    super.key,
    this.step = -1,
    this.fill = false,
    required this.tile,
    required this.glyph,
    required this.hero,
    required this.heroGlyph,
  });

  final int step;
  final bool fill;
  final Color tile;
  final Color glyph;
  final Color hero;
  final Color heroGlyph;

  @override
  Widget build(BuildContext context) {
    final art = CustomPaint(
      painter: _ArrowGridPainter(
        step: step,
        fill: fill,
        tile: tile,
        glyph: glyph,
        hero: hero,
        heroGlyph: heroGlyph,
      ),
    );
    return fill
        ? SizedBox.expand(child: art)
        : AspectRatio(aspectRatio: 1.5, child: art);
  }
}

class _ArrowGridPainter extends CustomPainter {
  const _ArrowGridPainter({
    required this.step,
    required this.fill,
    required this.tile,
    required this.glyph,
    required this.hero,
    required this.heroGlyph,
  });

  final int step;
  final bool fill;
  final Color tile;
  final Color glyph;
  final Color hero;
  final Color heroGlyph;

  static const _cols = 6;
  static const _tourRows = 4;
  static const _heroCol = 1;
  static const _tourHeroRow = 1;

  /// column, row, direction (0 right, 1 down, 2 left, 3 up).
  /// Row 1 right of the hero tile is empty, so its exit path is clear.
  static const _tourTiles = [
    [0, 0, 0],
    [2, 0, 1],
    [4, 0, 3],
    [5, 0, 2],
    [0, 1, 3],
    [1, 1, 0],
    [0, 2, 0],
    [2, 2, 2],
    [3, 2, 3],
    [5, 2, 1],
    [1, 3, 0],
    [3, 3, 0],
    [4, 3, 3],
  ];

  static const _mask = 0x7fffffff;

  static int _hash(int col, int row) {
    var x = (col * 73856093 + row * 19349663 + 83492791) & _mask;
    x = ((x ^ (x >> 15)) * 40503) & _mask;
    x = ((x ^ (x >> 13)) * 40503) & _mask;
    return x ^ (x >> 16);
  }

  /// Same pattern on every launch. The 3x3 block around the hero is left
  /// empty so the tap ring never cuts into a neighbouring tile.
  static List<List<int>> _fillTiles(int rows, int heroRow) {
    final tiles = <List<int>>[];
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < _cols; col++) {
        if ((col - _heroCol).abs() <= 1 && (row - heroRow).abs() <= 1) continue;
        final h = _hash(col, row);
        if (h % 100 < 55) tiles.add([col, row, (h >> 8) % 4]);
      }
    }
    tiles.add([_heroCol, heroRow, 0]);
    return tiles;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double cell;
    final int rows;
    if (fill) {
      cell = size.width / _cols;
      rows = math.max(1, (size.height / cell).floor());
    } else {
      cell = math.min(size.width / _cols, size.height / _tourRows);
      rows = _tourRows;
    }
    final dx = (size.width - cell * _cols) / 2;
    final dy = (size.height - cell * rows) / 2;
    final gap = cell * 0.08;
    final radius = Radius.circular(cell * 0.22);
    final heroRow = fill ? (rows - 1) ~/ 2 : _tourHeroRow;
    final tiles = fill ? _fillTiles(rows, heroRow) : _tourTiles;

    Rect rectFor(int col, int row) => Rect.fromLTWH(
      dx + col * cell + gap,
      dy + row * cell + gap,
      cell - 2 * gap,
      cell - 2 * gap,
    );

    for (final t in tiles) {
      final rect = rectFor(t[0], t[1]);
      final rrect = RRect.fromRectAndRadius(rect, radius);
      final isHero = t[0] == _heroCol && t[1] == heroRow;
      final outlined = isHero && step == 2;
      if (outlined) {
        canvas.drawRRect(
          rrect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = hero,
        );
      } else {
        canvas.drawRRect(rrect, Paint()..color = isHero ? hero : tile);
      }
      _arrow(
        canvas,
        rect,
        t[2],
        outlined ? hero : (isHero ? heroGlyph : glyph),
      );
    }

    final heroRect = rectFor(_heroCol, heroRow);
    if (step == 0) {
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(
        heroRect.center,
        cell * 0.62,
        ring..color = hero.withValues(alpha: 0.7),
      );
      canvas.drawCircle(
        heroRect.center,
        cell * 0.85,
        ring..color = hero.withValues(alpha: 0.3),
      );
    } else if (step == 1) {
      final end = dx + _cols * cell - gap;
      final dash = Paint()..color = hero.withValues(alpha: 0.9);
      for (var x = heroRect.right + gap * 2; x < end; x += cell * 0.28) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              x,
              heroRect.center.dy - cell * 0.03,
              math.min(cell * 0.14, end - x),
              cell * 0.06,
            ),
            Radius.circular(cell * 0.03),
          ),
          dash,
        );
      }
    } else if (step == 2) {
      final coin = Paint()..color = OnboardingTheme.coin;
      final shine = Paint()
        ..color = OnboardingTheme.bgTop.withValues(alpha: 0.2);
      for (final col in const [3, 5]) {
        final center = rectFor(col, heroRow).center;
        canvas.drawCircle(center, cell * 0.2, coin);
        canvas.drawCircle(center, cell * 0.11, shine);
      }
    }
  }

  void _arrow(Canvas canvas, Rect rect, int dir, Color color) {
    final h = rect.shortestSide * 0.3;
    final path = Path()
      ..moveTo(-h, -h * 0.28)
      ..lineTo(h * 0.1, -h * 0.28)
      ..lineTo(h * 0.1, -h * 0.7)
      ..lineTo(h, 0)
      ..lineTo(h * 0.1, h * 0.7)
      ..lineTo(h * 0.1, h * 0.28)
      ..lineTo(-h, h * 0.28)
      ..close();
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(dir * math.pi / 2);
    canvas.drawPath(path, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ArrowGridPainter old) =>
      old.step != step ||
      old.fill != fill ||
      old.tile != tile ||
      old.glyph != glyph ||
      old.hero != hero ||
      old.heroGlyph != heroGlyph;
}
