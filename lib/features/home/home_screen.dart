import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_identity.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.currentLevel,
    required this.onPlay,
  });

  final int currentLevel;
  final ValueChanged<int> onPlay;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Stack(
        children: [
          const Positioned.fill(child: _YardBackdrop()),
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 14, 25, 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _PhoolRastaMark(size: 43),
                    const SizedBox(width: 11),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppIdentity.name.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: 2.1,
                          ),
                        ),
                        const Text(
                          'FAHAD APPS',
                          style: TextStyle(
                            fontSize: 8,
                            letterSpacing: 2.0,
                            color: Color(0xff91a49e),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton.filledTonal(
                      onPressed: () => _showSettings(context),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xff25343a),
                        foregroundColor: const Color(0xfffff3d8),
                      ),
                      icon: const Icon(Icons.tune_rounded, size: 20),
                    ),
                  ],
                ),
                const Spacer(flex: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xff31463f).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xff61c69a).withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: Color(0xff61c69a),
                        size: 15,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'LAHORE  •  CHAPTER ONE',
                        style: TextStyle(
                          color: Color(0xffc6d2ca),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 17),
                const Text(
                  'The yard is\nwide open.',
                  style: TextStyle(
                    height: 0.98,
                    fontSize: 47,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.4,
                    color: Color(0xfffff3d8),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Guide every colorful ride to the road.\nFind the right order, then clear the way.',
                  style: TextStyle(
                    color: Color(0xffb2c1b9),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const Spacer(flex: 3),
                const _YardPreview(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => onPlay(currentLevel),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xffffb347),
                          foregroundColor: const Color(0xff182329),
                          padding: const EdgeInsets.symmetric(vertical: 17),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 25),
                        label: const Text(
                          'Start driving',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 15,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xff25343a),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            currentLevel.toString().padLeft(2, '0'),
                            style: const TextStyle(
                              color: Color(0xfffff3d8),
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'LEVEL',
                            style: const TextStyle(
                              color: Color(0xff91a49e),
                              fontSize: 8,
                              letterSpacing: 1.3,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    AppIdentity.tagline,
                    style: const TextStyle(
                      color: Color(0xff738781),
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  void _showSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xff25343a),
      showDragHandle: true,
      builder: (context) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 8, 22, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  color: Color(0xfffff3d8),
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'Sound, language and accessibility options are coming in a later build.',
                style: TextStyle(color: Color(0xffb2c1b9), height: 1.45),
              ),
              SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _YardPreview extends StatelessWidget {
  const _YardPreview();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xff202f35).withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(25),
      border: Border.all(
        color: const Color(0xff526764).withValues(alpha: 0.65),
      ),
    ),
    child: Column(
      children: [
        Row(
          children: [
            const Icon(
              Icons.local_shipping_rounded,
              color: Color(0xffffb347),
              size: 16,
            ),
            const SizedBox(width: 7),
            const Text(
              'THE TRUCK-ART YARD',
              style: TextStyle(
                fontSize: 9,
                color: Color(0xffc6d2ca),
                letterSpacing: 1.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xff61c69a),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            const Text(
              'READY',
              style: TextStyle(
                fontSize: 8,
                color: Color(0xff91a49e),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const AspectRatio(aspectRatio: 2.1, child: _PreviewBoard()),
      ],
    ),
  );
}

class _PreviewBoard extends StatelessWidget {
  const _PreviewBoard();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _PreviewBoardPainter());
}

class _PreviewBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xff1a272c);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(13)),
      background,
    );
    final grid = Paint()
      ..color = const Color(0xff3d5154)
      ..strokeWidth = 1;
    for (var i = 1; i < 6; i++) {
      final x = size.width * i / 6;
      final y = size.height * i / 4;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
      if (i < 4) canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    _drawMiniTruck(
      canvas,
      Rect.fromLTWH(
        size.width * 0.12,
        size.height * 0.17,
        size.width * 0.30,
        size.height * 0.28,
      ),
      const Color(0xffffb347),
      true,
    );
    _drawMiniTruck(
      canvas,
      Rect.fromLTWH(
        size.width * 0.45,
        size.height * 0.58,
        size.width * 0.35,
        size.height * 0.25,
      ),
      const Color(0xffed6ca7),
      false,
    );
    _drawMiniTruck(
      canvas,
      Rect.fromLTWH(
        size.width * 0.76,
        size.height * 0.13,
        size.width * 0.16,
        size.height * 0.55,
      ),
      const Color(0xff4ecac1),
      false,
      vertical: true,
    );
    final fleck = Paint()
      ..color = const Color(0xfffff3d8).withValues(alpha: 0.6);
    for (final point in [
      Offset(size.width * .35, size.height * .3),
      Offset(size.width * .64, size.height * .7),
      Offset(size.width * .82, size.height * .42),
    ]) {
      canvas.drawCircle(point, 2, fleck);
    }
  }

  void _drawMiniTruck(
    Canvas canvas,
    Rect rect,
    Color color,
    bool goesRight, {
    bool vertical = false,
  }) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(7)),
      Paint()..color = color,
    );
    final stripe = Paint()
      ..color = const Color(0xfffff3d8)
      ..strokeWidth = 2;
    if (vertical) {
      canvas.drawLine(
        Offset(rect.center.dx, rect.top + 5),
        Offset(rect.center.dx, rect.bottom - 5),
        stripe,
      );
    } else {
      canvas.drawLine(
        Offset(rect.left + 5, rect.center.dy),
        Offset(rect.right - 5, rect.center.dy),
        stripe,
      );
    }
    final cab = vertical
        ? Rect.fromLTWH(
            rect.left + 3,
            rect.top + 3,
            rect.width - 6,
            rect.height * 0.23,
          )
        : Rect.fromLTWH(
            goesRight ? rect.right - rect.width * 0.28 : rect.left + 3,
            rect.top + 3,
            rect.width * 0.23,
            rect.height - 6,
          );
    canvas.drawRRect(
      RRect.fromRectAndRadius(cab, const Radius.circular(5)),
      Paint()..color = color.withValues(alpha: .73),
    );
    final glint = Paint()..color = const Color(0xff183840);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cab.deflate(4), const Radius.circular(3)),
      glint,
    );
    canvas.drawCircle(
      Offset(rect.left + 8, rect.bottom - 1),
      3,
      Paint()..color = const Color(0xff182329),
    );
    canvas.drawCircle(
      Offset(rect.right - 8, rect.bottom - 1),
      3,
      Paint()..color = const Color(0xff182329),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PhoolRastaMark extends StatelessWidget {
  const _PhoolRastaMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _PhoolRastaMarkPainter()),
  );
}

class _PhoolRastaMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(14)),
      Paint()..color = const Color(0xff31463f),
    );
    final center = rect.center;
    final colors = [
      const Color(0xffffb347),
      const Color(0xffed6ca7),
      const Color(0xff4ecac1),
      const Color(0xff61c69a),
    ];
    for (var index = 0; index < colors.length; index++) {
      final angle = index * math.pi / 2;
      final petal = Rect.fromCenter(
        center:
            center +
            Offset(math.cos(angle), math.sin(angle)) * size.width * .19,
        width: size.width * .26,
        height: size.height * .26,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(petal, const Radius.circular(4)),
        Paint()..color = colors[index],
      );
    }
    canvas.drawCircle(
      center,
      size.width * .11,
      Paint()..color = const Color(0xfffff3d8),
    );
    final centerPaint = Paint()
      ..color = const Color(0xff31463f)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center + Offset(-size.width * .24, 0),
      center + Offset(size.width * .24, 0),
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _YardBackdrop extends StatelessWidget {
  const _YardBackdrop();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _BackdropPainter());
}

class _BackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader =
          const RadialGradient(
            colors: [Color(0xff31463f), Color(0xff182329)],
            stops: [0, 1],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * .52, size.height * .42),
              radius: size.width * .78,
            ),
          );
    canvas.drawRect(Offset.zero & size, glow);
    final paint = Paint()
      ..color = const Color(0xff516c63).withValues(alpha: .14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..moveTo(size.width * .78, 0)
      ..cubicTo(
        size.width * .38,
        size.height * .24,
        size.width * .9,
        size.height * .53,
        size.width * .55,
        size.height,
      );
    canvas.drawPath(path, paint);
    canvas.drawPath(
      path.shift(const Offset(13, 0)),
      paint..color = const Color(0xffffb347).withValues(alpha: .09),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
