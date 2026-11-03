import 'package:flutter/material.dart';

import '../app/theme_pack.dart';

/// Optional bundled fonts. Without them Flutter falls back to the system font.
abstract final class GameFonts {
  static const display = 'LilitaOne';
  static const body = 'Nunito';
}

/// Letter spacing breaks joined Urdu letters, so it only applies to English.
double letterSpacingFor(String language, double value) =>
    language == 'ur' ? 0 : value;

/// Dark yard gradient, soft colour glows and the hanging flag bunting.
class GameBackdrop extends StatelessWidget {
  const GameBackdrop({super.key, required this.child, this.bunting = true});

  final Widget child;
  final bool bunting;

  @override
  Widget build(BuildContext context) {
    const pack = ThemePack.truckArt;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [pack.asphalt, pack.panel],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: const Alignment(-1.3, -0.65),
            child: _Glow(color: pack.accent, size: 300),
          ),
          Align(
            alignment: const Alignment(1.3, 0.45),
            child: _Glow(color: pack.turquoise, size: 340),
          ),
          Align(
            alignment: const Alignment(-1.2, 0.95),
            child: _Glow(color: pack.floralMagenta, size: 260),
          ),
          if (bunting)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: SizedBox(
                    height: 40,
                    child: CustomPaint(painter: _BuntingPainter()),
                  ),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0)],
        ),
      ),
    ),
  );
}

class _BuntingPainter extends CustomPainter {
  const _BuntingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const pack = ThemePack.truckArt;
    final colors = [
      pack.accent,
      pack.coral,
      pack.turquoise,
      pack.floralMagenta,
    ];
    final string = Paint()
      ..color = pack.ivory.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(0, 8), Offset(size.width, 8), string);
    final flag = Paint();
    final count = (size.width / 26).ceil();
    for (var i = 0; i < count; i++) {
      final x = i * 26.0;
      flag.color = colors[i % colors.length];
      final path = Path()
        ..moveTo(x + 2, 10)
        ..lineTo(x + 24, 10)
        ..lineTo(x + 13, 36)
        ..close();
      canvas.drawPath(path, flag);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Round on/off switch with a sliding knob. Purely visual: the row around it
/// handles taps so the whole row is the touch target.
class GameToggle extends StatelessWidget {
  const GameToggle({super.key, required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    const pack = ThemePack.truckArt;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      width: 48,
      height: 28,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: value ? pack.turquoise : pack.ivory.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        alignment: value
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: value ? pack.asphalt : pack.ivory,
          ),
        ),
      ),
    );
  }
}

/// EN / Urdu pill switch.
class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const pack = ThemePack.truckArt;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: pack.ivory.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(pack, 'en', 'EN'),
          const SizedBox(width: 2),
          _segment(pack, 'ur', 'اردو'),
        ],
      ),
    );
  }

  Widget _segment(ThemePack pack, String code, String label) {
    final selected = value == code;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: selected ? null : () => onChanged(code),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? pack.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: selected ? pack.asphalt : pack.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

/// The game's bus, drawn with the active theme colours.
class BusIllustration extends StatelessWidget {
  const BusIllustration({
    super.key,
    required this.body,
    required this.stripe,
    this.width = 200,
  });

  final Color body;
  final Color stripe;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: width * 140 / 220,
    child: CustomPaint(
      painter: _BusPainter(body: body, stripe: stripe),
    ),
  );
}

class _BusPainter extends CustomPainter {
  const _BusPainter({required this.body, required this.stripe});

  final Color body;
  final Color stripe;

  @override
  void paint(Canvas canvas, Size size) {
    const pack = ThemePack.truckArt;
    canvas.save();
    canvas.scale(size.width / 220);
    final paint = Paint();

    final bodyShape = RRect.fromRectAndRadius(
      const Rect.fromLTWH(8, 40, 204, 72),
      const Radius.circular(20),
    );
    paint.color = body;
    canvas.drawRRect(bodyShape, paint);

    canvas.save();
    canvas.clipRRect(bodyShape);
    paint.color = stripe;
    canvas.drawRect(const Rect.fromLTWH(8, 88, 204, 14), paint);
    canvas.restore();

    for (var i = 0; i < 4; i++) {
      final x = 24.0 + i * 38;
      paint.color = pack.asphalt;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 52, 30, 24),
          const Radius.circular(6),
        ),
        paint,
      );
      paint.color = pack.ivory.withValues(alpha: 0.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 3, 55, 10, 8),
          const Radius.circular(3),
        ),
        paint,
      );
    }

    paint.color = pack.ivory;
    for (var i = 0; i < 9; i++) {
      canvas.drawCircle(Offset(22.0 + i * 22, 95), 4, paint);
    }

    paint.color = pack.accent;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(190, 60, 16, 22),
        const Radius.circular(5),
      ),
      paint,
    );

    for (final cx in const [56.0, 164.0]) {
      paint.color = pack.asphalt;
      canvas.drawCircle(Offset(cx, 114), 17, paint);
      paint.color = pack.ivory;
      canvas.drawCircle(Offset(cx, 114), 7, paint);
    }

    final arrow = Path()
      ..moveTo(96, 12)
      ..lineTo(124, 12)
      ..lineTo(124, 2)
      ..lineTo(146, 20)
      ..lineTo(124, 38)
      ..lineTo(124, 28)
      ..lineTo(96, 28)
      ..close();
    paint.color = pack.ivory;
    canvas.drawPath(arrow, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BusPainter oldDelegate) =>
      oldDelegate.body != body || oldDelegate.stripe != stripe;
}

/// Chunky game button with a 3D edge that presses down when tapped.
class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.foreground,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? foreground;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  var _down = false;

  bool get _enabled => widget.onPressed != null;

  void _setDown(bool value) {
    if (_down != value && mounted) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    const pack = ThemePack.truckArt;
    final color = widget.color ?? pack.accent;
    final edge = Color.lerp(color, Colors.black, 0.32)!;
    final pressed = _down && _enabled;
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      onTap: widget.onPressed,
      excludeSemantics: true,
      child: Opacity(
        opacity: _enabled ? 1 : 0.45,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enabled ? (_) => _setDown(true) : null,
          onTapUp: _enabled ? (_) => _setDown(false) : null,
          onTapCancel: () => _setDown(false),
          onTap: widget.onPressed,
          child: SizedBox(
            height: 62,
            child: Align(
              alignment: Alignment.topCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                margin: EdgeInsets.only(top: pressed ? 4 : 0),
                width: double.infinity,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(offset: Offset(0, pressed ? 1 : 5), color: edge),
                  ],
                ),
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: GameFonts.display,
                    fontSize: 20,
                    color: widget.foreground ?? pack.asphalt,
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
