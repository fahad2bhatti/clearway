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

/// Small accent label that sits above a headline.
class OnboardingKicker extends StatelessWidget {
  const OnboardingKicker(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: OnboardingTheme.label.copyWith(
      color: OnboardingTheme.accent,
      fontSize: 12,
    ),
  );
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

  /// Letter spacing breaks joined Urdu letters, so Urdu callers pass 0.
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
                          letterSpacing: letterSpacing,
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
class ArrowGridArt extends StatelessWidget {
  const ArrowGridArt({
    super.key,
    this.step = -1,
    required this.tile,
    required this.glyph,
    required this.hero,
    required this.heroGlyph,
  });

  final int step;
  final Color tile;
  final Color glyph;
  final Color hero;
  final Color heroGlyph;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1.5,
    child: CustomPaint(
      painter: _ArrowGridPainter(
        step: step,
        tile: tile,
        glyph: glyph,
        hero: hero,
        heroGlyph: heroGlyph,
      ),
    ),
  );
}

class _ArrowGridPainter extends CustomPainter {
  const _ArrowGridPainter({
    required this.step,
    required this.tile,
    required this.glyph,
    required this.hero,
    required this.heroGlyph,
  });

  final int step;
  final Color tile;
  final Color glyph;
  final Color hero;
  final Color heroGlyph;

  static const _cols = 6;
  static const _rows = 4;
  static const _heroIndex = 5;

  /// column, row, direction (0 right, 1 down, 2 left, 3 up).
  /// Row 1 right of the hero tile is empty, so its exit path is clear.
  static const _tiles = [
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

  @override
  void paint(Canvas canvas, Size size) {
    final cell = math.min(size.width / _cols, size.height / _rows);
    final dx = (size.width - cell * _cols) / 2;
    final dy = (size.height - cell * _rows) / 2;
    final gap = cell * 0.08;
    final radius = Radius.circular(cell * 0.22);

    Rect rectFor(int col, int row) => Rect.fromLTWH(
      dx + col * cell + gap,
      dy + row * cell + gap,
      cell - 2 * gap,
      cell - 2 * gap,
    );

    for (var i = 0; i < _tiles.length; i++) {
      final t = _tiles[i];
      final rect = rectFor(t[0], t[1]);
      final rrect = RRect.fromRectAndRadius(rect, radius);
      final isHero = i == _heroIndex;
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

    final heroRect = rectFor(1, 1);
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
      for (final col in const [3, 5]) {
        final center = rectFor(col, 1).center;
        canvas.drawCircle(center, cell * 0.2, Paint()..color = OnboardingTheme.coin);
        canvas.drawCircle(
          center,
          cell * 0.11,
          Paint()..color = const Color(0x33000000),
        );
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
      old.tile != tile ||
      old.glyph != glyph ||
      old.hero != hero ||
      old.heroGlyph != heroGlyph;
}
