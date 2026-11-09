import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../features/onboarding/onboarding_theme.dart';

/// "Level cleared!" result dialog.
///
/// Motion: the card pops in with a bounce, the earned stars fly in one by one
/// with a sparkle, the coin counter ticks up and confetti falls once. The
/// optional ad button doubles the reward and ticks the counter up again.
class LevelClearDialog extends StatefulWidget {
  const LevelClearDialog({
    super.key,
    required this.title,
    required this.stars,
    required this.coinsEarned,
    required this.coinsLabel,
    required this.starsLabel,
    required this.nextLabel,
    required this.onNext,
    required this.replayLabel,
    required this.onReplay,
    this.homeLabel,
    this.onHome,
    this.note,
    this.adLabel,
    this.adDoneLabel,
    this.adFailedMessage = '',
    this.onAd,
  });

  final String title;
  final int stars;
  final int coinsEarned;

  /// Builds the pill text for a coin amount, e.g. `+25 coins`.
  final String Function(int coins) coinsLabel;

  /// Screen-reader text for the star row, e.g. `2 of 3 stars`.
  final String starsLabel;
  final String nextLabel;
  final VoidCallback onNext;
  final String replayLabel;
  final VoidCallback onReplay;
  final String? homeLabel;
  final VoidCallback? onHome;
  final String? note;
  final String? adLabel;
  final String? adDoneLabel;
  final String adFailedMessage;

  /// Shows the rewarded ad. Returns true only when the reward was earned.
  final Future<bool> Function()? onAd;

  @override
  State<LevelClearDialog> createState() => _LevelClearDialogState();
}

class _LevelClearDialogState extends State<LevelClearDialog>
    with TickerProviderStateMixin {
  static const _coinTick = Interval(0.62, 0.85, curve: Curves.easeOut);
  static const _confettiColorCount = 5;

  late final AnimationController _master = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  late final AnimationController _confetti = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  late final AnimationController _bonus = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  late final List<_ConfettiPiece> _pieces = _ConfettiPiece.generate(
    48,
    _confettiColorCount,
  );

  var _started = false;
  var _adBusy = false;
  var _adFailed = false;
  var _doubled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _master.value = 1;
      _confetti.value = 1;
    } else {
      _master.forward();
      _confetti.forward();
    }
  }

  @override
  void dispose() {
    _master.dispose();
    _confetti.dispose();
    _bonus.dispose();
    super.dispose();
  }

  int get _shownCoins {
    final base = (widget.coinsEarned * _coinTick.transform(_master.value))
        .round();
    if (!_doubled) return base;
    final extra = (widget.coinsEarned * Curves.easeOut.transform(_bonus.value))
        .round();
    return base + extra;
  }

  Future<void> _watchAd() async {
    final onAd = widget.onAd;
    if (onAd == null || _adBusy || _doubled) return;
    setState(() {
      _adBusy = true;
      _adFailed = false;
    });
    final rewarded = await onAd();
    if (!mounted) return;
    setState(() {
      _adBusy = false;
      _doubled = rewarded;
      _adFailed = !rewarded;
    });
    if (rewarded) {
      if (MediaQuery.of(context).disableAnimations) {
        _bonus.value = 1;
      } else {
        _bonus.forward(from: 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = math.min(340.0, MediaQuery.sizeOf(context).width - 56);
    final confettiColors = <Color>[
      OnboardingTheme.coin,
      OnboardingTheme.teal,
      OnboardingTheme.cream,
      OnboardingTheme.muted,
      Colors.white,
    ];
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_master, _bonus]),
                  builder: (context, _) => _card(width),
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: CustomPaint(
              painter: _ConfettiPainter(
                pieces: _pieces,
                animation: _confetti,
                colors: confettiColors,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(double width) {
    final pop = const Interval(0, 0.25).transform(_master.value);
    final scale = 0.6 + 0.4 * Curves.easeOutBack.transform(pop);
    final fade = const Interval(0, 0.12).transform(_master.value);
    return Opacity(
      opacity: fade,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: width,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          decoration: BoxDecoration(
            color: OnboardingTheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: OnboardingTheme.line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: OnboardingTheme.teal.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_outward_rounded,
                  size: 32,
                  color: OnboardingTheme.teal,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: OnboardingTheme.display(38),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: widget.starsLabel,
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [for (var i = 0; i < 3; i++) _star(i)],
                  ),
                ),
              ),
              if (widget.coinsEarned > 0) ...[
                const SizedBox(height: 10),
                _coinPill(),
              ],
              if (widget.note != null) ...[
                const SizedBox(height: 10),
                Text(
                  widget.note!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: OnboardingTheme.muted,
                    fontSize: 12,
                  ),
                ),
              ],
              if (widget.adLabel != null && widget.onAd != null) ...[
                const SizedBox(height: 14),
                _adButton(),
              ],
              const SizedBox(height: 20),
              _ResultButton(
                label: widget.nextLabel,
                primary: true,
                onTap: widget.onNext,
              ),
              const SizedBox(height: 10),
              _ResultButton(
                label: widget.replayLabel,
                primary: false,
                onTap: widget.onReplay,
              ),
              if (widget.homeLabel != null && widget.onHome != null)
                TextButton(
                  onPressed: widget.onHome,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  child: Text(
                    widget.homeLabel!,
                    style: const TextStyle(
                      color: OnboardingTheme.muted,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              else
                const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _star(int index) {
    final filled = index < widget.stars;
    final begin = 0.22 + 0.1 * index;
    final flight = filled
        ? Interval(begin, begin + 0.2).transform(_master.value)
        : 1.0;
    final burst = filled
        ? Interval(begin + 0.14, begin + 0.34).transform(_master.value)
        : 0.0;
    final eased = Curves.easeOutBack.transform(flight);
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: flight,
            child: Transform.translate(
              offset: Offset(0, -40 * (1 - eased)),
              child: Transform.scale(
                scale: 1 + 1.4 * (1 - eased),
                child: CustomPaint(
                  size: const Size(40, 40),
                  painter: _SparkleStarPainter(
                    filled
                        ? OnboardingTheme.coin
                        : OnboardingTheme.line,
                  ),
                ),
              ),
            ),
          ),
          if (burst > 0 && burst < 1)
            CustomPaint(
              size: const Size(48, 48),
              painter: _SparkleBurstPainter(burst),
            ),
        ],
      ),
    );
  }

  Widget _coinPill() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: OnboardingTheme.surfaceAlt,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: OnboardingTheme.line),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: OnboardingTheme.coin,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          widget.coinsLabel(_shownCoins),
          style: OnboardingTheme.display(20, color: OnboardingTheme.coin),
        ),
      ],
    ),
  );

  Widget _adButton() {
    final done = _doubled;
    final label = done
        ? (widget.adDoneLabel ?? widget.adLabel!)
        : widget.adLabel!;
    return Column(
      children: [
        Semantics(
          button: true,
          enabled: !_adBusy && !done,
          label: label,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _adBusy || done ? null : _watchAd,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: done
                    ? OnboardingTheme.teal.withValues(alpha: 0.16)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: OnboardingTheme.teal),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_adBusy)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: OnboardingTheme.teal,
                      ),
                    )
                  else
                    Icon(
                      done
                          ? Icons.check_circle_rounded
                          : Icons.play_circle_fill_rounded,
                      size: 20,
                      color: OnboardingTheme.teal,
                    ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: OnboardingTheme.teal,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_adFailed && widget.adFailedMessage.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            widget.adFailedMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: OnboardingTheme.muted, fontSize: 11),
          ),
        ],
      ],
    );
  }
}

/// Flat pill button: accent fill for the main action, outlined for the rest.
class _ResultButton extends StatelessWidget {
  const _ResultButton({
    required this.label,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    onTap: onTap,
    excludeSemantics: true,
    child: Material(
      color: primary ? OnboardingTheme.accent : OnboardingTheme.surfaceAlt,
      shape: StadiumBorder(
        side: primary
            ? BorderSide.none
            : const BorderSide(color: OnboardingTheme.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: Center(
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                color: primary
                    ? OnboardingTheme.onAccent
                    : OnboardingTheme.cream,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Four-point sparkle star, as in the Figma rating row.
class _SparkleStarPainter extends CustomPainter {
  const _SparkleStarPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 2;
    final k = r * 0.3;
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + k, c.dy - k, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + k, c.dy + k, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - k, c.dy + k, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - k, c.dy - k, c.dx, c.dy - r)
      ..close();
    canvas
      ..drawPath(path, Paint()..color = color)
      ..drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeJoin = StrokeJoin.round,
      );
  }

  @override
  bool shouldRepaint(_SparkleStarPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Short ray burst drawn where a star lands.
class _SparkleBurstPainter extends CustomPainter {
  const _SparkleBurstPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final paint = Paint()
      ..color = OnboardingTheme.cream.withValues(alpha: 1 - progress)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final start = 18 + 8 * progress;
    final end = start + 7 * (1 - progress);
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final dir = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(c + dir * start, c + dir * end, paint);
    }
  }

  @override
  bool shouldRepaint(_SparkleBurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ConfettiPiece {
  const _ConfettiPiece({
    required this.x,
    required this.delay,
    required this.speed,
    required this.size,
    required this.spin,
    required this.phase,
    required this.color,
    required this.round,
  });

  final double x;
  final double delay;
  final double speed;
  final double size;
  final double spin;
  final double phase;
  final int color;
  final bool round;

  static List<_ConfettiPiece> generate(int count, int colorCount) {
    final random = math.Random(11);
    return List.generate(
      count,
      (_) => _ConfettiPiece(
        x: random.nextDouble(),
        delay: random.nextDouble() * 0.35,
        speed: 0.75 + random.nextDouble() * 0.5,
        size: 6 + random.nextDouble() * 6,
        spin: (random.nextDouble() - 0.5) * 14,
        phase: random.nextDouble() * math.pi * 2,
        color: random.nextInt(colorCount),
        round: random.nextBool(),
      ),
    );
  }
}

/// Confetti that falls once from the top of the screen and fades out.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.pieces,
    required this.animation,
    required this.colors,
  }) : super(repaint: animation);

  final List<_ConfettiPiece> pieces;
  final Animation<double> animation;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    if (t <= 0 || t >= 1) return;
    final paint = Paint();
    for (final piece in pieces) {
      final local = ((t - piece.delay) / (1 - piece.delay))
          .clamp(0.0, 1.0)
          .toDouble();
      if (local <= 0 || local >= 1) continue;
      final y = -20 + local * piece.speed * (size.height + 40);
      final x = piece.x * size.width + math.sin(local * 6 + piece.phase) * 18;
      final fade = local > 0.8 ? (1 - local) / 0.2 : 1.0;
      paint.color = colors[piece.color].withValues(alpha: fade);
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(local * piece.spin);
      if (piece.round) {
        canvas.drawCircle(Offset.zero, piece.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: piece.size,
              height: piece.size * 0.55,
            ),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.animation != animation || oldDelegate.pieces != pieces;
}
