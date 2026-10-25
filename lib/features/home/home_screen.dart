import 'package:flutter/material.dart';

import '../../widgets/clearway_banner.dart';

import '../../app/app_identity.dart';
import '../../core/clearway_strings.dart';
import '../../core/daily_clock.dart';
import '../../data/local_save.dart';
import '../../game/data/level_catalog.dart';
import '../../services/cloud_progress_sync.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.currentLevel,
    required this.save,
    required this.cloudStatus,
    required this.onSyncNow,
    required this.onPlay,
    required this.onDaily,
  });

  final int currentLevel;
  final LocalSave save;
  final CloudSyncStatus cloudStatus;
  final VoidCallback onSyncNow;
  final ValueChanged<int> onPlay;
  final VoidCallback onDaily;

  ClearwayStrings get strings => ClearwayStrings(save.language);

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: const ClearwayBanner(),
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
                    const _ClearwayMark(size: 43),
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
                    Text(
                      '🪙 ${save.coins}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: switch (cloudStatus) {
                        CloudSyncStatus.synced => strings.synced,
                        CloudSyncStatus.syncing => strings.syncing,
                        CloudSyncStatus.offline => strings.offline,
                        CloudSyncStatus.failed => strings.cloudError,
                        CloudSyncStatus.notConfigured =>
                          strings.cloudUnavailable,
                      },
                      onPressed: onSyncNow,
                      icon: Icon(
                        cloudStatus == CloudSyncStatus.synced
                            ? Icons.cloud_done_rounded
                            : Icons.cloud_off_rounded,
                        size: 18,
                        color: cloudStatus == CloudSyncStatus.synced
                            ? const Color(0xff61c69a)
                            : const Color(0xff91a49e),
                      ),
                    ),
                    const SizedBox(width: 7),
                    IconButton.filledTonal(
                      onPressed: () => _showSettings(context, save),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xff25343a),
                        foregroundColor: const Color(0xfffff3d8),
                      ),
                      icon: const Icon(Icons.tune_rounded, size: 20),
                    ),
                  ],
                ),
                const Spacer(flex: 2),
                Text(
                  strings.homeHeadline,
                  style: const TextStyle(
                    height: 0.98,
                    fontSize: 47,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.4,
                    color: Color(0xfffff3d8),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  strings.homeDescription,
                  style: const TextStyle(
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
                          backgroundColor: const Color(0xffff5c8d),
                          foregroundColor: const Color(0xff0b232e),
                          padding: const EdgeInsets.symmetric(vertical: 17),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 25),
                        label: Text(
                          strings.startDriving,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showLevels(context, save, onPlay),
                      child: Container(
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
                              strings.level,
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
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDaily,
                        icon: const Icon(Icons.calendar_month_rounded),
                        label: StreamBuilder<int>(
                          stream: Stream<int>.periodic(
                            const Duration(minutes: 1),
                            (minute) => minute,
                          ),
                          builder: (context, snapshot) => Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${strings.rushHour}  •  ${strings.dailyWithStreak(save.streak)}',
                              ),
                              Text(
                                strings.newPuzzleIn(
                                  DailyClock.countdownLabel(),
                                ),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    IconButton.filledTonal(
                      tooltip: strings.dailyCalendar,
                      onPressed: () => showCalendar(context, save),
                      icon: const Icon(Icons.calendar_view_month_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _showShop(context, save),
                    icon: const Icon(Icons.storefront_rounded, size: 18),
                    label: Text(strings.yardShop),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    strings.tagline,
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

  void _showSettings(BuildContext context, LocalSave save) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xff25343a),
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.settings,
                  style: const TextStyle(
                    color: Color(0xfffff3d8),
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SwitchListTile(
                  title: Text(strings.sound),
                  value: save.sound,
                  onChanged: (v) {
                    save.sound = v;
                    save.save();
                    update(() {});
                  },
                ),
                SwitchListTile(
                  title: Text(strings.music),
                  value: save.music,
                  onChanged: (v) {
                    save.music = v;
                    save.save();
                    update(() {});
                  },
                ),
                SwitchListTile(
                  title: Text(strings.haptics),
                  value: save.haptics,
                  onChanged: (v) {
                    save.haptics = v;
                    save.save();
                    update(() {});
                  },
                ),
                SwitchListTile(
                  title: Text(strings.darkTheme),
                  value: save.darkTheme,
                  onChanged: (v) {
                    save.darkTheme = v;
                    save.save();
                    update(() {});
                  },
                ),
                SwitchListTile(
                  title: Text(strings.colorblind),
                  value: save.colorblind,
                  onChanged: (v) {
                    save.colorblind = v;
                    save.save();
                    update(() {});
                  },
                ),
                ListTile(
                  title: Text(strings.languageLabel),
                  trailing: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'en', label: Text('EN')),
                      ButtonSegment(value: 'ur', label: Text('اردو')),
                    ],
                    selected: {save.language},
                    onSelectionChanged: (v) {
                      save.language = v.first;
                      save.save();
                      update(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showShop(BuildContext context, LocalSave save) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xff25343a),
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      strings.yardShop,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text('🪙 ${save.coins}'),
                  ],
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(
                    Icons.lightbulb,
                    color: Color(0xffffb347),
                  ),
                  title: Text(strings.hints3),
                  subtitle: Text(strings.hintDescription),
                  trailing: const Text('40 🪙'),
                  onTap: () {
                    if (save.coins < 40) return;
                    save.coins -= 40;
                    save.hints += 3;
                    save.save();
                    update(() {});
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.undo, color: Color(0xff4ecac1)),
                  title: Text(strings.undos3),
                  subtitle: Text(strings.undoDescription),
                  trailing: const Text('30 🪙'),
                  onTap: () {
                    if (save.coins < 30) return;
                    save.coins -= 30;
                    save.undos += 3;
                    save.save();
                    update(() {});
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.card_giftcard,
                    color: Color(0xffed6ca7),
                  ),
                  title: Text(strings.practiceReward),
                  subtitle: Text(strings.offlineDemoReward),
                  trailing: const Text('+20 🪙'),
                  onTap: () {
                    save.coins += 20;
                    save.save();
                    update(() {});
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLevels(
    BuildContext context,
    LocalSave save,
    ValueChanged<int> onPlay,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff25343a),
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  strings.chooseYard,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: LevelCatalog.totalLevels,
                  itemBuilder: (context, index) {
                    final number = index + 1;
                    final unlocked = number <= save.level;
                    final stars = save.stars[number] ?? 0;
                    return InkWell(
                      onTap: unlocked
                          ? () {
                              Navigator.pop(context);
                              onPlay(number);
                            }
                          : null,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        decoration: BoxDecoration(
                          color: unlocked
                              ? const Color(0xff35474b)
                              : const Color(0xff202a2e),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: number == currentLevel
                                ? const Color(0xffffb347)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              unlocked ? '$number' : '🔒',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (unlocked)
                              Text(
                                '★' * stars + '☆' * (3 - stars),
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: Color(0xffffb347),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showCalendar(BuildContext context, LocalSave save) {
    final strings = ClearwayStrings(save.language);
    final currentUtc = DailyClock.utcNow();
    var month = DateTime.utc(currentUtc.year, currentUtc.month);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff25343a),
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) {
          final daysInMonth = DateTime.utc(month.year, month.month + 1, 0).day;
          final leading = DateTime.utc(month.year, month.month, 1).weekday - 1;
          final currentMonth = DailyClock.utcNow();
          final completed = [
            for (var day = 1; day <= daysInMonth; day++)
              if (save.completedDailies.contains(
                _dateKey(month.year, month.month, day),
              ))
                day,
          ];
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 5, 18, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => update(
                          () =>
                              month = DateTime.utc(month.year, month.month - 1),
                        ),
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Expanded(
                        child: Text(
                          '${strings.monthName(month.month)} ${month.year}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed:
                            month.year == currentMonth.year &&
                                month.month == currentMonth.month
                            ? null
                            : () => update(
                                () => month = DateTime.utc(
                                  month.year,
                                  month.month + 1,
                                ),
                              ),
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                  Text(
                    strings.calendarProgress(completed.length, daysInMonth),
                    style: const TextStyle(
                      color: Color(0xffc6d2ca),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 14),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 7,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    children: [
                      for (final weekday
                          in (save.language == 'ur'
                              ? ['د', 'پ', 'م', 'ب', 'ج', 'ہ', 'ا']
                              : ['M', 'T', 'W', 'T', 'F', 'S', 'S']))
                        Center(
                          child: Text(
                            weekday,
                            style: const TextStyle(
                              color: Color(0xff91a49e),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      for (var i = 0; i < leading; i++) const SizedBox.shrink(),
                      for (var day = 1; day <= daysInMonth; day++)
                        Container(
                          decoration: BoxDecoration(
                            color: completed.contains(day)
                                ? const Color(0xff38554f)
                                : const Color(0xff1d2a2f),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(color: const Color(0xff405357)),
                          ),
                          child: Center(
                            child: Text(
                              completed.contains(day) ? '★' : '$day',
                              style: TextStyle(
                                color: completed.contains(day)
                                    ? const Color(0xffffb347)
                                    : const Color(0xfffff3d8),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static String _dateKey(int year, int month, int day) =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
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
              Icons.arrow_forward_rounded,
              color: Color(0xffff5c8d),
              size: 16,
            ),
            const SizedBox(width: 7),
            const Text(
              'THE ARROW BOARD',
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
    final t = size.height * 0.11;
    _drawMiniArrow(
      canvas,
      Offset(size.width * 0.08, size.height * 0.28),
      Offset(size.width * 0.46, size.height * 0.28),
      const Color(0xffff5c8d),
      t,
    );
    _drawMiniArrow(
      canvas,
      Offset(size.width * 0.72, size.height * 0.76),
      Offset(size.width * 0.38, size.height * 0.76),
      const Color(0xff5fe6af),
      t,
    );
    _drawMiniArrow(
      canvas,
      Offset(size.width * 0.62, size.height * 0.12),
      Offset(size.width * 0.62, size.height * 0.50),
      const Color(0xff4ecac1),
      t,
    );
    _drawMiniArrow(
      canvas,
      Offset(size.width * 0.89, size.height * 0.88),
      Offset(size.width * 0.89, size.height * 0.14),
      const Color(0xffffb347),
      t,
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

  void _drawMiniArrow(
    Canvas canvas,
    Offset tail,
    Offset tip,
    Color color,
    double thickness,
  ) {
    final delta = tip - tail;
    final dir = delta / delta.distance;
    final normal = Offset(-dir.dy, dir.dx);
    final headLength = thickness * 1.9;
    final headHalf = thickness * 1.15;
    final base = tip - dir * headLength;

    void draw(Offset shift, Color c) {
      final paint = Paint()..color = c;
      canvas.drawLine(
        tail + shift,
        base + dir * 1.5 + shift,
        Paint()
          ..color = c
          ..strokeWidth = thickness
          ..strokeCap = StrokeCap.round,
      );
      final head = Path()
        ..moveTo(tip.dx + shift.dx, tip.dy + shift.dy)
        ..lineTo(
          base.dx + normal.dx * headHalf + shift.dx,
          base.dy + normal.dy * headHalf + shift.dy,
        )
        ..lineTo(
          base.dx - normal.dx * headHalf + shift.dx,
          base.dy - normal.dy * headHalf + shift.dy,
        )
        ..close();
      canvas.drawPath(head, paint);
    }

    draw(
      const Offset(0, 2.5),
      Color.lerp(color, const Color(0xff000000), 0.38)!,
    );
    draw(Offset.zero, color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ClearwayMark extends StatelessWidget {
  const _ClearwayMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * 0.26),
    child: Image.asset(
      'assets/icon/icon_full_1024.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
    ),
  );
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
            colors: [Color(0xff12323d), Color(0xff0b232e)],
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
      paint..color = const Color(0xffff5c8d).withValues(alpha: .10),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
