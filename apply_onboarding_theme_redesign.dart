// Run from the Clearway project root:
//   dart apply_onboarding_theme_redesign.dart --dry
//   dart apply_onboarding_theme_redesign.dart
import 'dart:io';

const marker = '// onboarding-theme-v2';
const path = 'lib/features/onboarding/onboarding_theme.dart';

const replacement = r'''abstract final class OnboardingTheme {
  // onboarding-theme-v2
  // Values mirror ThemePack.arrowNight (navy + mint). Names are kept so
  // existing screens compile; only the colours changed.
  static const Color bgTop = Color(0xFF0B1020);
  static const Color bgBottom = Color(0xFF111831);
  static const Color cream = Color(0xFFF2F4FA);
  static const Color gold = Color(0xFF6EE7C8);
  static const Color goldDark = Color(0xFF45B89E);
  static const Color teal = Color(0xFF6EE7C8);
  static const Color muted = Color(0xFF9AA3BF);
  static const Color deepPurple = Color(0xFF0B1020);
  static const Color cardPurple = Color(0xFF151D38);
  static const Color cardPurpleDark = Color(0xFF111831);

  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgTop, bgBottom],
  );

  static const LinearGradient logoTile = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gold, gold],
  );

  static BoxDecoration primaryButton = BoxDecoration(
    color: gold,
    borderRadius: BorderRadius.circular(28),
  );

  static const TextStyle wordmark = TextStyle(
    fontSize: 48,
    color: cream,
    letterSpacing: 2,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle tagline = TextStyle(
    fontSize: 18,
    color: gold,
    letterSpacing: 3,
    fontWeight: FontWeight.w700,
  );
}''';

void main(List<String> args) {
  final dry = args.contains('--dry');
  final file = File(path);
  if (!file.existsSync()) {
    stdout.writeln('❌ $path nahi mila. Project root se chalao.');
    exit(1);
  }
  var src = file.readAsStringSync();

  if (src.contains(marker)) {
    stdout.writeln('⏭️  Pehle se applied (onboarding-theme-v2). Kuch nahi badla.');
    return;
  }

  const anchor = 'abstract final class OnboardingTheme {';
  final start = src.indexOf(anchor);
  if (start < 0) {
    stdout.writeln('❌ OnboardingTheme class nahi mili. File badli hui hai?');
    exit(1);
  }
  final close = _matchBrace(src, start + anchor.length - 1);
  if (close < 0) {
    stdout.writeln('❌ Class ka closing brace match nahi hua.');
    exit(1);
  }
  stdout.writeln('✅ OnboardingTheme class mili (${close + 1 - start} chars)');

  src = src.replaceRange(start, close + 1, replacement);
  stdout.writeln('✅ Navy + mint rang lage, 3D gold shadow hata di');

  if (dry) {
    stdout.writeln('🔍 --dry: file nahi likhi.');
    return;
  }

  final home = Platform.environment['HOME'] ?? '.';
  final dir = Directory('$home/clearway_backups')..createSync(recursive: true);
  final ts = DateTime.now().millisecondsSinceEpoch;
  final backup = '${dir.path}/onboarding_theme_$ts.dart';
  file.copySync(backup);
  stdout.writeln('✅ Backup: $backup');

  file.writeAsStringSync(src);
  stdout.writeln('✅ $path likh di. Ab: dart format $path && dart analyze');
}

/// Finds the matching '}' for the '{' at [open]. Skips strings and comments.
int _matchBrace(String s, int open) {
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
    if (c == '{') depth++;
    if (c == '}') {
      depth--;
      if (depth == 0) return i;
    }
    i++;
  }
  return -1;
}
