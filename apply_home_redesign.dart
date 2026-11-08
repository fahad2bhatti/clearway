// Run from the Clearway project root (after apply_onboarding_theme_v3.dart):
//   dart apply_home_redesign.dart --dry
//   dart apply_home_redesign.dart
import 'dart:io';

const marker = '// home-v2';
const path = 'lib/features/home/home_screen.dart';
const themePath = 'lib/features/onboarding/onboarding_theme.dart';

const buildExpr = r'''Widget build(BuildContext context) => Scaffold(
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
  );''';

const contentExpr = r'''Widget _content(BuildContext context) => Column(
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
  );''';

const newClasses = r'''// home-v2
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
}''';

const removeList = [
  '_SyncPill',
  '_CoinChip',
  '_SquareAction',
  '_TrophyButton',
  '_TrophyButtonState',
  '_ShopButton',
  '_GiftChip',
  '_LevelPill',
  '_DailyRushCard',
  '_BoardCard',
  '_Bunting',
  '_BuntingPainter',
  '_HomeBackdrop',
  '_BackdropPainter',
  '_PlayPulse',
  '_PlayPulseState',
];

var src = '';

void main(List<String> args) {
  final dry = args.contains('--dry');
  final file = File(path);
  if (!file.existsSync()) {
    stdout.writeln('❌ $path nahi mila. Project root se chalao.');
    exit(1);
  }
  final theme = File(themePath);
  if (!theme.existsSync() ||
      !theme.readAsStringSync().contains('onboarding-theme-v3')) {
    stdout.writeln('❌ Pehle dart apply_onboarding_theme_v3.dart chalao.');
    exit(1);
  }
  src = file.readAsStringSync();
  if (src.contains(marker)) {
    stdout.writeln('⏭️  Pehle se applied (home-v2). Kuch nahi badla.');
    return;
  }

  _must('HomeScreen.build', replaceExpr(
      'Widget build(BuildContext context) => Scaffold(', buildExpr));
  _must('HomeScreen._content', replaceExpr(
      'Widget _content(BuildContext context) => Column(', contentExpr));

  for (final name in removeList) {
    _must('purani class $name hatai', removeClass(name));
  }

  const oldBoardBg = 'Paint()..color = const Color(0xff241A5E)';
  if (src.contains(oldBoardBg)) {
    src = src.replaceFirst(
        oldBoardBg, 'Paint()..color = OnboardingTheme.surfaceAlt');
    stdout.writeln('✅ Board background theme token se joda');
  } else {
    stdout.writeln('⚠️  Board background line nahi mili, skip (koi masla nahi)');
  }

  src = '${src.trimRight()}\n\n$newClasses\n';
  stdout.writeln('✅ Naye widgets lage (hero, board card, daily card, menu tiles)');

  if (dry) {
    stdout.writeln('🔍 --dry: file nahi likhi.');
    return;
  }

  final home = Platform.environment['HOME'] ?? '.';
  final dir = Directory('$home/clearway_backups')..createSync(recursive: true);
  final backup =
      '${dir.path}/home_screen_${DateTime.now().millisecondsSinceEpoch}.dart';
  file.copySync(backup);
  stdout.writeln('✅ Backup: $backup');

  file.writeAsStringSync(src);
  stdout.writeln('✅ $path likh di. Ab: dart format $path && dart analyze');
}

void _must(String what, bool ok) {
  if (ok) {
    stdout.writeln('✅ $what');
  } else {
    stdout.writeln('❌ $what nahi mila. Kuch nahi likha.');
    exit(1);
  }
}

bool replaceExpr(String anchor, String replacement) {
  final start = src.indexOf(anchor);
  if (start < 0) return false;
  final close = _matchClose(src, start + anchor.length - 1);
  if (close < 0) return false;
  var end = close + 1;
  if (end < src.length && src[end] == ';') end++;
  src = src.replaceRange(start, end, replacement);
  return true;
}

bool removeClass(String name) {
  final m = RegExp('^class ${RegExp.escape(name)}\\b', multiLine: true)
      .firstMatch(src);
  if (m == null) return false;
  final brace = src.indexOf('{', m.start);
  if (brace < 0) return false;
  final close = _matchClose(src, brace);
  if (close < 0) return false;
  var start = m.start;
  while (start > 1) {
    final prevStart = src.lastIndexOf('\n', start - 2) + 1;
    final line = src.substring(prevStart, start - 1).trim();
    if (line.startsWith('///')) {
      start = prevStart;
    } else {
      break;
    }
  }
  var end = close + 1;
  while (end < src.length && src[end] == '\n') {
    end++;
  }
  src = src.replaceRange(start, end, '');
  return true;
}

int _matchClose(String s, int open) {
  final openCh = s[open];
  final closeCh = openCh == '(' ? ')' : '}';
  var depth = 0;
  var i = open;
  while (i < s.length) {
    final c = s[i];
    if (c == '/' && i + 1 < s.length && s[i + 1] == '/') {
      final nl = s.indexOf('\n', i);
      if (nl < 0) return -1;
      i = nl;
      continue;
    }
    if (c == '/' && i + 1 < s.length && s[i + 1] == '*') {
      final e = s.indexOf('*/', i + 2);
      if (e < 0) return -1;
      i = e + 2;
      continue;
    }
    if (c == "'" || c == '"') {
      i++;
      while (i < s.length && s[i] != c) {
        if (s[i] == '\\') i++;
        i++;
      }
      i++;
      continue;
    }
    if (c == openCh) depth++;
    if (c == closeCh) {
      depth--;
      if (depth == 0) return i;
    }
    i++;
  }
  return -1;
}
