// Run from the Clearway project root (after apply_home_redesign.dart):
//   dart apply_home_sheets_redesign.dart --dry
//   dart apply_home_sheets_redesign.dart
import 'dart:io';

const marker = '// sheets-v2';
const path = 'lib/features/home/home_screen.dart';
const themePath = 'lib/features/onboarding/onboarding_theme.dart';

const sheetShell = r'''// sheets-v2
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
}''';

const sheetNav = r'''class _SheetNavButton extends StatelessWidget {
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
}''';

const levelTile = r'''class _LevelTile extends StatelessWidget {
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
}''';

const calendarDay = r'''class _CalendarDay extends StatelessWidget {
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
}''';

const goalCard = r'''Widget _goalCard({
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
  }''';

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
    stdout.writeln('⏭️  Pehle se applied (sheets-v2). Kuch nahi badla.');
    return;
  }
  if (!src.contains('// home-v2')) {
    stdout.writeln('❌ Pehle dart apply_home_redesign.dart chalao.');
    exit(1);
  }

  _must('_SheetShell', replaceClass('_SheetShell', sheetShell));
  _must('_SheetNavButton', replaceClass('_SheetNavButton', sheetNav));
  _must('_LevelTile', replaceClass('_LevelTile', levelTile));
  _must('_CalendarDay', replaceClass('_CalendarDay', calendarDay));
  _must('_GoalsSheet._goalCard', replaceMethod('Widget _goalCard(', goalCard));

  if (dry) {
    stdout.writeln('🔍 --dry: file nahi likhi.');
    return;
  }

  final home = Platform.environment['HOME'] ?? '.';
  final dir = Directory('$home/clearway_backups')..createSync(recursive: true);
  final backup =
      '${dir.path}/home_screen_sheets_${DateTime.now().millisecondsSinceEpoch}.dart';
  file.copySync(backup);
  stdout.writeln('✅ Backup: $backup');

  file.writeAsStringSync(src);
  stdout.writeln('✅ $path likh di. Ab: dart format $path && dart analyze');
}

void _must(String what, bool ok) {
  if (ok) {
    stdout.writeln('✅ $what badla');
  } else {
    stdout.writeln('❌ $what nahi mila. Kuch nahi likha.');
    exit(1);
  }
}

bool replaceClass(String name, String replacement) {
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
  src = src.replaceRange(start, close + 1, replacement);
  return true;
}

/// Replaces a block-bodied method: finds "anchor(" params, then its { body }.
bool replaceMethod(String anchor, String replacement) {
  final start = src.indexOf(anchor);
  if (start < 0) return false;
  final parenClose = _matchClose(src, start + anchor.length - 1);
  if (parenClose < 0) return false;
  final bodyOpen = src.indexOf('{', parenClose);
  if (bodyOpen < 0) return false;
  final bodyClose = _matchClose(src, bodyOpen);
  if (bodyClose < 0) return false;
  src = src.replaceRange(start, bodyClose + 1, replacement);
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
