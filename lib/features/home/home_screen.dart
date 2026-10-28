import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../widgets/clearway_banner.dart';

import '../../app/app_identity.dart';
import '../../core/clearway_strings.dart';
import '../../core/daily_clock.dart';
import '../../data/local_save.dart';
import '../../game/data/level_catalog.dart';
import '../../services/ad_service.dart';
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
          const Positioned.fill(child: RepaintBoundary(child: _YardBackdrop())),
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
                const RepaintBoundary(child: _YardPreview()),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _PlayPulse(
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
                        label: _DailyRushLabel(
                          strings: strings,
                          streak: save.streak,
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
                Row(
                  children: [
                    if (save.giftDay != DailyClock.dayKey())
                      FilledButton.tonalIcon(
                        onPressed: () => _claimDailyGift(context),
                        icon: const Icon(Icons.card_giftcard_rounded, size: 18),
                        label: Text(
                          strings.dailyGift(LocalSave.dailyGiftCoins),
                        ),
                      ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _showShop(context, save),
                      icon: const Icon(Icons.storefront_rounded, size: 18),
                      label: Text(strings.yardShop),
                    ),
                  ],
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

  Future<void> _claimDailyGift(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final today = DailyClock.dayKey();
    if (save.giftDay == today) return;
    AdService.preload();
    final rewarded = await AdService.showRewarded();
    if (!rewarded) {
      messenger.showSnackBar(SnackBar(content: Text(strings.adNotReady)));
      return;
    }
    save.giftDay = today;
    save.coins += LocalSave.dailyGiftCoins;
    await save.save();
    messenger.showSnackBar(
      SnackBar(content: Text(strings.giftClaimed(LocalSave.dailyGiftCoins))),
    );
  }

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
                  title: Text(strings.freeCoinsAd),
                  subtitle: Text(strings.freeCoinsLeft(save.adCoinsLeft)),
                  trailing: Text('+${LocalSave.adCoinsReward} 🪙'),
                  enabled: save.adCoinsLeft > 0,
                  onTap: () async {
                    if (save.adCoinsLeft <= 0) return;
                    final messenger = ScaffoldMessenger.of(context);
                    AdService.preload();
                    final rewarded = await AdService.showRewarded();
                    if (!rewarded) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(strings.adNotReady)),
                      );
                      return;
                    }
                    save.recordAdCoins();
                    save.coins += LocalSave.adCoinsReward;
                    await save.save();
                    if (context.mounted) update(() {});
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

/// "Rush Hour" button label. Owns its own once-a-minute timer so only this
/// label rebuilds for the countdown, and the timer is cancelled on dispose.
class _DailyRushLabel extends StatefulWidget {
  const _DailyRushLabel({required this.strings, required this.streak});

  final ClearwayStrings strings;
  final int streak;

  @override
  State<_DailyRushLabel> createState() => _DailyRushLabelState();
}

class _DailyRushLabelState extends State<_DailyRushLabel> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${strings.rushHour}  •  ${strings.dailyWithStreak(widget.streak)}',
        ),
        Text(
          strings.newPuzzleIn(DailyClock.countdownLabel()),
          style: const TextStyle(fontSize: 10),
        ),
      ],
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

/// Ek arrow ka demo: kab nikalta hai aur kab wapas aata hai
/// (sab waqt controller ke 0..1 cycle ke hisab se).
class _MiniArrow {
  const _MiniArrow({
    required this.tail,
    required this.tip,
    required this.color,
    required this.exitStart,
    required this.exitEnd,
    required this.returnStart,
    required this.returnEnd,
  });

  final Offset tail;
  final Offset tip;
  final Color color;
  final double exitStart;
  final double exitEnd;
  final double returnStart;
  final double returnEnd;
}

const _previewArrows = <_MiniArrow>[
  _MiniArrow(
    tail: Offset(0.08, 0.28),
    tip: Offset(0.46, 0.28),
    color: Color(0xffff5c8d),
    exitStart: 0.06,
    exitEnd: 0.20,
    returnStart: 0.66,
    returnEnd: 0.76,
  ),
  _MiniArrow(
    tail: Offset(0.62, 0.12),
    tip: Offset(0.62, 0.50),
    color: Color(0xff4ecac1),
    exitStart: 0.16,
    exitEnd: 0.30,
    returnStart: 0.70,
    returnEnd: 0.80,
  ),
  _MiniArrow(
    tail: Offset(0.89, 0.88),
    tip: Offset(0.89, 0.14),
    color: Color(0xffffb347),
    exitStart: 0.26,
    exitEnd: 0.40,
    returnStart: 0.74,
    returnEnd: 0.84,
  ),
  _MiniArrow(
    tail: Offset(0.72, 0.76),
    tip: Offset(0.38, 0.76),
    color: Color(0xff5fe6af),
    exitStart: 0.36,
    exitEnd: 0.50,
    returnStart: 0.78,
    returnEnd: 0.88,
  ),
];

/// Home ka demo board: arrows ek ek kar ke apni direction mein screen se
/// nikalte hain, phir wapas aate hain (game jaisa).
class _PreviewBoard extends StatefulWidget {
  const _PreviewBoard();

  @override
  State<_PreviewBoard> createState() => _PreviewBoardState();
}

class _PreviewBoardState extends State<_PreviewBoard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Phone mein "reduce motion" on ho to animation band rahe.
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _PreviewBoardPainter(_controller));
}

class _PreviewBoardPainter extends CustomPainter {
  _PreviewBoardPainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final boardRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(13),
    );
    canvas.drawRRect(boardRect, Paint()..color = const Color(0xff1a272c));
    final grid = Paint()
      ..color = const Color(0xff3d5154)
      ..strokeWidth = 1;
    for (var i = 1; i < 6; i++) {
      final x = size.width * i / 6;
      final y = size.height * i / 4;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
      if (i < 4) canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final thickness = size.height * 0.11;
    canvas.save();
    canvas.clipRRect(boardRect);
    for (final arrow in _previewArrows) {
      _paintArrow(canvas, size, arrow, t, thickness);
    }
    canvas.restore();

    // Chhote dots halka sa chamakte hain.
    final flecks = [
      Offset(size.width * .35, size.height * .3),
      Offset(size.width * .64, size.height * .7),
      Offset(size.width * .82, size.height * .42),
    ];
    for (var i = 0; i < flecks.length; i++) {
      final twinkle = 0.5 + 0.5 * math.sin(2 * math.pi * (t * 4 + i / 3));
      final alpha = 0.25 + 0.4 * twinkle;
      canvas.drawCircle(
        flecks[i],
        2,
        Paint()..color = const Color(0xfffff3d8).withValues(alpha: alpha),
      );
    }
  }

  void _paintArrow(
    Canvas canvas,
    Size size,
    _MiniArrow arrow,
    double t,
    double thickness,
  ) {
    final tail = Offset(
      size.width * arrow.tail.dx,
      size.height * arrow.tail.dy,
    );
    final tip = Offset(size.width * arrow.tip.dx, size.height * arrow.tip.dy);
    final delta = tip - tail;
    final dir = delta / delta.distance;
    final horizontal = dir.dx.abs() > dir.dy.abs();
    // Board se poora bahar nikalne ka fasla.
    final distance =
        (horizontal
            ? (dir.dx > 0 ? size.width - tail.dx : tail.dx)
            : (dir.dy > 0 ? size.height - tail.dy : tail.dy)) +
        thickness * 3;

    void drawShifted(double move, double alpha, [double scale = 1]) {
      canvas.save();
      final center = (tail + tip) / 2;
      canvas.translate(dir.dx * move, dir.dy * move);
      if (scale != 1) {
        canvas.translate(center.dx, center.dy);
        canvas.scale(scale);
        canvas.translate(-center.dx, -center.dy);
      }
      _drawMiniArrow(
        canvas,
        tail,
        tip,
        arrow.color.withValues(alpha: alpha),
        thickness,
      );
      canvas.restore();
    }

    if (t >= arrow.exitStart && t < arrow.exitEnd) {
      final p = (t - arrow.exitStart) / (arrow.exitEnd - arrow.exitStart);
      // Nikalne se pehle thoda sa peeche kheenchta hai, phir tez ho jata hai.
      final windUp = p < 0.15
          ? -thickness * 0.6 * math.sin(p / 0.15 * math.pi)
          : 0.0;
      final move = distance * Curves.easeInCubic.transform(p) + windUp;
      if (p > 0.15) {
        for (final ghost in const [(0.10, 0.16), (0.20, 0.08)]) {
          final gp = (p - ghost.$1).clamp(0.0, 1.0);
          drawShifted(distance * Curves.easeInCubic.transform(gp), ghost.$2);
        }
      }
      drawShifted(move, 1);
    } else if (t >= arrow.exitEnd && t < arrow.returnStart) {
      return; // board se nikal chuka hai
    } else if (t >= arrow.returnStart && t < arrow.returnEnd) {
      final p = (t - arrow.returnStart) / (arrow.returnEnd - arrow.returnStart);
      final alpha = Curves.easeOut.transform((p * 1.6).clamp(0.0, 1.0));
      final scale = 0.8 + 0.2 * Curves.easeOutBack.transform(p);
      drawShifted(0, alpha, scale);
    } else {
      drawShifted(0, 1);
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

    // Shadow ka alpha arrow ke alpha jaisa rahe (fade ke waqt bhi).
    draw(
      const Offset(0, 2.5),
      Color.lerp(
        color.withValues(alpha: 1),
        const Color(0xff000000),
        0.38,
      )!.withValues(alpha: color.a),
    );
    draw(Offset.zero, color);
  }

  @override
  bool shouldRepaint(covariant _PreviewBoardPainter oldDelegate) =>
      oldDelegate.animation != animation;
}

/// Play button halka sa dhadakta hai (scale + glow), dhyan kheenchne ke liye.
class _PlayPulse extends StatefulWidget {
  const _PlayPulse({required this.child});

  final Widget child;

  @override
  State<_PlayPulse> createState() => _PlayPulseState();
}

class _PlayPulseState extends State<_PlayPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) {
      final e = Curves.easeInOut.transform(_controller.value);
      return Transform.scale(
        scale: 1 + 0.02 * e,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xffff5c8d)
                    .withValues(alpha: 0.12 + 0.22 * e),
                blurRadius: 10 + 12 * e,
                spreadRadius: 1 + 2 * e,
              ),
            ],
          ),
          child: child,
        ),
      );
    },
  );
}

class _ClearwayMark extends StatelessWidget {
  const _ClearwayMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * 0.26),
    child: Image.asset(
      'assets/images/clearway_mark.png',
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
