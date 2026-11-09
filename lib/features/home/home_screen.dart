import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/clearway_strings.dart';
import '../../core/daily_clock.dart';
import '../../data/local_save.dart';
import '../../game/achievements/achievement_models.dart';
import '../../game/data/level_catalog.dart';
import '../../services/ad_service.dart';
import '../../services/cloud_progress_sync.dart';
import '../../services/economy_repository.dart';
import '../../widgets/clearway_banner.dart';
import '../onboarding/onboarding_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.currentLevel,
    required this.save,
    required this.cloudStatus,
    required this.onSyncNow,
    required this.onPlay,
    required this.onDaily,
    required this.onShop,
    required this.onSettings,
  });

  final int currentLevel;
  final LocalSave save;
  final CloudSyncStatus cloudStatus;
  final VoidCallback onSyncNow;
  final ValueChanged<int> onPlay;
  final VoidCallback onDaily;
  final VoidCallback onShop;
  final VoidCallback onSettings;

  static const _pink = Color(0xffff5c8d);

  ClearwayStrings get strings => ClearwayStrings(save.language);

  @override
  Widget build(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: false,
    backgroundColor: OnboardingTheme.bgTop,
    bottomNavigationBar: const ClearwayBanner(),
    body: SafeArea(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: _content(context),
      ),
    ),
  );

  Widget _content(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          _SyncPill(
            status: cloudStatus,
            strings: strings,
            ur: save.language == 'ur',
            onTap: onSyncNow,
          ),
          const Spacer(),
          _CoinChip(coins: save.coins),
          const SizedBox(width: 8),
          _SquareAction(
            icon: Icons.tune_rounded,
            color: OnboardingTheme.cream,
            tooltip: strings.settings,
            onTap: onSettings,
          ),
        ],
      ),
      const SizedBox(height: 20),
      _HeroCard(
        label: strings.level,
        level: currentLevel,
        playLabel: strings.startDriving,
        levelsTooltip: strings.chooseYard,
        onPlay: () => onPlay(currentLevel),
        onLevels: () => _showLevels(context, save, onPlay),
      ),
      const SizedBox(height: 12),
      const RepaintBoundary(child: _BoardCard()),
      const SizedBox(height: 12),
      _DailyRushCard(
        strings: strings,
        streak: save.streak,
        onTap: onDaily,
        onCalendar: () => showCalendar(context, save),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _MenuTile(
              label: strings.achievements,
              showDot: _hasClaimableReward(save),
              onTap: () => _showGoals(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MenuTile(label: strings.yardShop, onTap: onShop),
          ),
        ],
      ),
      if (save.giftDay != DailyClock.dayKey()) ...[
        const SizedBox(height: 12),
        _GiftChip(
          label: strings.dailyGift(LocalSave.dailyGiftCoins),
          onTap: () => _claimDailyGift(context),
        ),
      ],
    ],
  );

  static bool _hasClaimableReward(LocalSave save) {
    final hasClaimableAchievement = AchievementCatalog.definitions.any(
      (definition) =>
          !save.claimedAchievements.contains(definition.id) &&
          (save.achievementProgress[definition.id] ?? 0) >= definition.target,
    );
    final missions = save.dailyMissions;
    final hasClaimableMission =
        missions?.missions.any(
          (mission) =>
              !missions.claimed.contains(mission.id) &&
              (missions.progress[mission.id] ?? 0) >= mission.target,
        ) ??
        false;
    return hasClaimableAchievement || hasClaimableMission;
  }

  Future<void> _claimDailyGift(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final today = DailyClock.dayKey();
    if (save.giftDay == today) return;
    AdService.preload();
    final rewarded = await AdService.showRewarded();
    if (!rewarded) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(strings.adNotReady),
            action: SnackBarAction(
              label: strings.tryAgain,
              onPressed: () {
                if (context.mounted) _claimDailyGift(context);
              },
            ),
          ),
        );
      return;
    }

    save.giftDay = today;
    save.coins += LocalSave.dailyGiftCoins;
    await save.save();
    messenger.showSnackBar(
      SnackBar(content: Text(strings.giftClaimed(LocalSave.dailyGiftCoins))),
    );
  }

  void _showGoals(BuildContext context) {
    _showClearwaySheet(
      context,
      title: strings.achievements,
      icon: Icons.emoji_events_rounded,
      accent: OnboardingTheme.gold,
      heightFactor: 0.88,
      builder: (_) => _GoalsSheet(save: save, strings: strings),
    );
  }

  void _showLevels(
    BuildContext context,
    LocalSave save,
    ValueChanged<int> onPlay,
  ) {
    _showClearwaySheet(
      context,
      title: strings.chooseYard,
      icon: Icons.grid_view_rounded,
      accent: _pink,
      heightFactor: 0.8,
      fill: true,
      builder: (sheetContext) => GridView.builder(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemCount: LevelCatalog.totalLevels,
        itemBuilder: (context, index) {
          final number = index + 1;
          return _LevelTile(
            number: number,
            unlocked: number <= save.level,
            current: number == currentLevel,
            stars: save.stars[number] ?? 0,
            onTap: () {
              Navigator.pop(sheetContext);
              onPlay(number);
            },
          );
        },
      ),
    );
  }

  static void showCalendar(BuildContext context, LocalSave save) {
    final strings = ClearwayStrings(save.language);
    final currentUtc = DailyClock.utcNow();
    var month = DateTime.utc(currentUtc.year, currentUtc.month);
    _showClearwaySheet(
      context,
      title: strings.dailyCalendar,
      icon: Icons.calendar_month_rounded,
      accent: OnboardingTheme.teal,
      builder: (_) => StatefulBuilder(
        builder: (context, update) {
          final daysInMonth = DateTime.utc(month.year, month.month + 1, 0).day;
          final leading = DateTime.utc(month.year, month.month, 1).weekday - 1;
          final now = DailyClock.utcNow();
          final isCurrentMonth =
              month.year == now.year && month.month == now.month;
          final completed = <int>{
            for (var day = 1; day <= daysInMonth; day++)
              if (save.completedDailies.contains(
                _dateKey(month.year, month.month, day),
              ))
                day,
          };
          final weekdays = save.language == 'ur'
              ? ['د', 'پ', 'م', 'ب', 'ج', 'ہ', 'ا']
              : ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _SheetNavButton(
                      icon: Icons.chevron_left_rounded,
                      onTap: () => update(
                        () => month = DateTime.utc(month.year, month.month - 1),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${strings.monthName(month.month)} ${month.year}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: OnboardingTheme.cream,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _SheetNavButton(
                      icon: Icons.chevron_right_rounded,
                      onTap: isCurrentMonth
                          ? null
                          : () => update(
                              () => month = DateTime.utc(
                                month.year,
                                month.month + 1,
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  strings.calendarProgress(completed.length, daysInMonth),
                  style: const TextStyle(
                    color: OnboardingTheme.teal,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  children: [
                    for (final weekday in weekdays)
                      Center(
                        child: Text(
                          weekday,
                          style: const TextStyle(
                            color: OnboardingTheme.muted,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    for (var i = 0; i < leading; i++) const SizedBox.shrink(),
                    for (var day = 1; day <= daysInMonth; day++)
                      _CalendarDay(
                        day: day,
                        done: completed.contains(day),
                        today: isCurrentMonth && day == now.day,
                        future: isCurrentMonth && day > now.day,
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _dateKey(int year, int month, int day) =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// Shared bottom-sheet look (Choose a level / Achievements / Daily calendar)
// ---------------------------------------------------------------------------

Future<void> _showClearwaySheet(
  BuildContext context, {
  required String title,
  required IconData icon,
  required Color accent,
  required WidgetBuilder builder,
  double heightFactor = 0.85,
  bool fill = false,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  barrierColor: Colors.black.withValues(alpha: 0.6),
  builder: (sheetContext) => _SheetShell(
    title: title,
    icon: icon,
    accent: accent,
    heightFactor: heightFactor,
    fill: fill,
    child: Builder(builder: builder),
  ),
);

// sheets-v2
class _SheetShell extends StatelessWidget {
  const _SheetShell({
    required this.title,
    required this.icon,
    required this.accent,
    required this.heightFactor,
    required this.fill,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final double heightFactor;
  final bool fill;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * heightFactor;
    final body = Column(
      mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: OnboardingTheme.line,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
          child: Row(
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OnboardingTheme.display(26),
                ),
              ),
              _SheetNavButton(
                icon: Icons.close_rounded,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        if (fill) Expanded(child: child) else Flexible(child: child),
      ],
    );
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SizedBox(
        height: fill ? maxHeight : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: OnboardingTheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: OnboardingTheme.line),
          ),
          // Ink (level tiles, Claim button) must paint on a Material that
          // sits ABOVE the decoration, otherwise it would be hidden.
          child: Material(
            type: MaterialType.transparency,
            child: SafeArea(top: false, child: body),
          ),
        ),
      ),
    );
  }
}

class _SheetNavButton extends StatelessWidget {
  const _SheetNavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: onTap,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: OnboardingTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OnboardingTheme.line),
      ),
      child: Icon(
        icon,
        size: 22,
        color: onTap == null
            ? OnboardingTheme.muted.withValues(alpha: 0.3)
            : OnboardingTheme.cream,
      ),
    ),
  );
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.number,
    required this.unlocked,
    required this.current,
    required this.stars,
    required this.onTap,
  });

  final int number;
  final bool unlocked;
  final bool current;
  final int stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BoxDecoration decoration;
    if (current) {
      decoration = BoxDecoration(
        color: OnboardingTheme.accent,
        borderRadius: BorderRadius.circular(14),
      );
    } else if (unlocked) {
      decoration = BoxDecoration(
        color: OnboardingTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OnboardingTheme.line),
      );
    } else {
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OnboardingTheme.line.withValues(alpha: 0.5)),
      );
    }
    final numberColor = current
        ? OnboardingTheme.onAccent
        : OnboardingTheme.cream;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: unlocked ? onTap : null,
      child: Ink(
        decoration: decoration,
        child: Center(
          child: unlocked
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$number',
                      style: OnboardingTheme.display(22, color: numberColor),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < 3; i++)
                          Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: i < stars
                                ? (current
                                      ? OnboardingTheme.onAccent
                                      : OnboardingTheme.accent)
                                : numberColor.withValues(alpha: 0.2),
                          ),
                      ],
                    ),
                  ],
                )
              : Icon(
                  Icons.lock_rounded,
                  size: 18,
                  color: OnboardingTheme.muted.withValues(alpha: 0.45),
                ),
        ),
      ),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.day,
    required this.done,
    required this.today,
    required this.future,
  });

  final int day;
  final bool done;
  final bool today;
  final bool future;

  @override
  Widget build(BuildContext context) {
    final Color border = done
        ? OnboardingTheme.accent
        : today
        ? OnboardingTheme.cream
        : OnboardingTheme.line;
    return Container(
      decoration: BoxDecoration(
        color: done
            ? OnboardingTheme.accent.withValues(alpha: 0.16)
            : OnboardingTheme.surfaceAlt.withValues(alpha: future ? 0.4 : 1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: today ? 1.5 : 1),
      ),
      child: Center(
        child: done
            ? const Icon(
                Icons.star_rounded,
                color: OnboardingTheme.accent,
                size: 20,
              )
            : Text(
                '$day',
                style: TextStyle(
                  color: today
                      ? OnboardingTheme.cream
                      : OnboardingTheme.cream.withValues(
                          alpha: future ? 0.35 : 0.9,
                        ),
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

class _GoalsSheet extends StatefulWidget {
  const _GoalsSheet({required this.save, required this.strings});

  final LocalSave save;
  final ClearwayStrings strings;

  @override
  State<_GoalsSheet> createState() => _GoalsSheetState();
}

class _GoalsSheetState extends State<_GoalsSheet> {
  @override
  void initState() {
    super.initState();
    widget.save.ensureDailyMissions();
  }

  @override
  Widget build(BuildContext context) {
    final daily = widget.save.dailyMissions!;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 28),
      children: [
        for (final definition in AchievementCatalog.definitions)
          _goalCard(
            icon: Icons.emoji_events_rounded,
            color: OnboardingTheme.gold,
            title: widget.strings.achievementName(definition.id),
            subtitle: widget.strings.coinsReward(definition.coins),
            progress: widget.save.achievementProgress[definition.id] ?? 0,
            target: definition.target,
            claimed: widget.save.claimedAchievements.contains(definition.id),
            onClaim: () => _claimAchievement(definition),
          ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            widget.strings.missions.toUpperCase(),
            style: const TextStyle(
              color: OnboardingTheme.muted,
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        for (final mission in daily.missions)
          _goalCard(
            icon: Icons.flag_rounded,
            color: OnboardingTheme.teal,
            title: widget.strings.missionName(mission.id),
            subtitle: widget.strings.coinsReward(mission.coins),
            progress: daily.progress[mission.id] ?? 0,
            target: mission.target,
            claimed: daily.claimed.contains(mission.id),
            onClaim: () => _claimMission(mission),
          ),
      ],
    );
  }

  Widget _goalCard({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    required int progress,
    required int target,
    required bool claimed,
    required VoidCallback onClaim,
  }) {
    final shown = progress.clamp(0, target);
    final complete = progress >= target;
    final ready = complete && !claimed;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OnboardingTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ready ? OnboardingTheme.accent : OnboardingTheme.line,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: claimed ? color.withValues(alpha: 0.4) : color,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: OnboardingTheme.cream.withValues(
                      alpha: claimed ? 0.55 : 1,
                    ),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: target == 0 ? 1 : shown / target,
                    minHeight: 6,
                    backgroundColor: OnboardingTheme.line,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.strings.progressLabel(shown, target)}'
                  '${subtitle == null ? '' : '  •  $subtitle'}',
                  style: const TextStyle(
                    color: OnboardingTheme.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: claimed
                ? Row(
                    key: const ValueKey('claimed'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_rounded,
                        color: OnboardingTheme.teal,
                        size: 18,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        widget.strings.claimed,
                        style: const TextStyle(
                          color: OnboardingTheme.teal,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  )
                : complete
                ? Semantics(
                    key: const ValueKey('claim'),
                    button: true,
                    label: widget.strings.claim,
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onClaim,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: OnboardingTheme.accent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.strings.claim.toUpperCase(),
                          style: const TextStyle(
                            color: OnboardingTheme.onAccent,
                            fontSize: 12,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('none')),
          ),
        ],
      ),
    );
  }

  Future<void> _claimAchievement(AchievementDefinition definition) async {
    final claimed = await EconomyRepository(widget.save)
        .claimAchievement(definition.id);
    if (claimed && mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.strings.achievementComplete}  '
            '${widget.strings.coinsReward(definition.coins)}',
          ),
        ),
      );
    }
  }

  Future<void> _claimMission(DailyMissionDefinition mission) async {
    final claimed = await EconomyRepository(widget.save)
        .claimDailyMission(mission.id);
    if (claimed && mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.strings.missionComplete}  '
            '${widget.strings.coinsReward(mission.coins)}',
          ),
        ),
      );
    }
  }
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
    canvas.drawRRect(boardRect, Paint()..color = OnboardingTheme.surfaceAlt);
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
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
        Paint()..color = OnboardingTheme.cream.withValues(alpha: alpha),
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

// ---------------------------------------------------------------------------
// New home widgets (Figma design)
// ---------------------------------------------------------------------------

/// Owns its own 1-second timer so only this label rebuilds for the
/// countdown; the timer is cancelled on dispose.
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
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _countdown() {
    final s = DailyClock.untilNextUtcDay().inSeconds.clamp(0, 86399);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(s ~/ 3600)}:${two((s % 3600) ~/ 60)}:${two(s % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.dailyWithStreak(widget.streak),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: OnboardingTheme.cream,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          strings.newPuzzleIn(_countdown()),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: OnboardingTheme.teal,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// home-v2
class _SyncPill extends StatelessWidget {
  const _SyncPill({
    required this.status,
    required this.strings,
    required this.ur,
    required this.onTap,
  });

  final CloudSyncStatus status;
  final ClearwayStrings strings;
  final bool ur;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ok = status == CloudSyncStatus.synced;
    final label = switch (status) {
      CloudSyncStatus.synced => ur ? strings.synced : 'Synced',
      CloudSyncStatus.syncing => ur ? strings.syncing : 'Syncing…',
      CloudSyncStatus.offline => ur ? strings.offline : 'Offline',
      CloudSyncStatus.failed => ur ? strings.cloudError : 'Sync error',
      CloudSyncStatus.notConfigured =>
        ur ? strings.cloudUnavailable : 'Local only',
    };
    final color = ok ? OnboardingTheme.teal : OnboardingTheme.muted;
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              ok ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
              size: 22,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _CoinChip extends StatelessWidget {
  const _CoinChip({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: OnboardingTheme.surface,
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
        Text('$coins', style: OnboardingTheme.display(18)),
      ],
    ),
  );
}

/// Flat bordered icon button (settings / calendar).
class _SquareAction extends StatelessWidget {
  const _SquareAction({
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip ?? '',
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: OnboardingTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: OnboardingTheme.line),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    ),
  );
}

/// Level + PLAY. Ghost level number sits behind, cropped by the card.
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.label,
    required this.level,
    required this.playLabel,
    required this.levelsTooltip,
    required this.onPlay,
    required this.onLevels,
  });

  final String label;
  final int level;
  final String playLabel;
  final String levelsTooltip;
  final VoidCallback onPlay;
  final VoidCallback onLevels;

  @override
  Widget build(BuildContext context) => Material(
    color: OnboardingTheme.accent,
    borderRadius: BorderRadius.circular(20),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      children: [
        Positioned(
          right: -8,
          bottom: -28,
          child: Text(
            '$level',
            style: OnboardingTheme.display(
              150,
              color: OnboardingTheme.onAccent.withValues(alpha: 0.14),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: OnboardingTheme.label.copyWith(
                  color: OnboardingTheme.onAccent.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$level',
                style: OnboardingTheme.display(
                  76,
                  color: OnboardingTheme.onAccent,
                ),
              ),
              const SizedBox(height: 16),
              Material(
                color: OnboardingTheme.onAccent,
                borderRadius: BorderRadius.circular(30),
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: onPlay,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 14,
                    ),
                    child: Text(
                      playLabel.toUpperCase(),
                      style: const TextStyle(
                        color: OnboardingTheme.accent,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Tooltip(
            message: levelsTooltip,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onLevels,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.grid_view_rounded,
                  size: 22,
                  color: OnboardingTheme.onAccent.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _BoardCard extends StatelessWidget {
  const _BoardCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: OnboardingTheme.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: OnboardingTheme.line),
    ),
    child: const AspectRatio(aspectRatio: 1.6, child: _PreviewBoard()),
  );
}

class _DailyRushCard extends StatelessWidget {
  const _DailyRushCard({
    required this.strings,
    required this.streak,
    required this.onTap,
    required this.onCalendar,
  });

  final ClearwayStrings strings;
  final int streak;
  final VoidCallback onTap;
  final VoidCallback onCalendar;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
        decoration: BoxDecoration(
          color: OnboardingTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: OnboardingTheme.line),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.local_fire_department_rounded,
              color: OnboardingTheme.hot,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DailyRushLabel(strings: strings, streak: streak),
            ),
            const SizedBox(width: 8),
            _SquareAction(
              icon: Icons.calendar_month_rounded,
              color: OnboardingTheme.muted,
              tooltip: strings.dailyCalendar,
              onTap: onCalendar,
            ),
          ],
        ),
      ),
    ),
  );
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.label,
    required this.onTap,
    this.showDot = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: OnboardingTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: OnboardingTheme.line),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: OnboardingTheme.cream,
                  fontSize: 13,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (showDot)
              const CircleAvatar(radius: 4, backgroundColor: HomeScreen._pink),
          ],
        ),
      ),
    ),
  );
}

class _GiftChip extends StatelessWidget {
  const _GiftChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: OnboardingTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: HomeScreen._pink.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            const CircleAvatar(radius: 4, backgroundColor: HomeScreen._pink),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: OnboardingTheme.cream,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
