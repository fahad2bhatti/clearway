// Run from the Clearway project root:
//   dart apply_onboarding_theme_v3.dart --dry
//   dart apply_onboarding_theme_v3.dart
import 'dart:io';

const marker = '// onboarding-theme-v3';
const path = 'lib/features/onboarding/onboarding_theme.dart';

const replacement = r'''abstract final class OnboardingTheme {
  // onboarding-theme-v3
  // FitGenie-style palette. Old names are kept so existing screens compile.
  static const Color bgTop = Color(0xFF0C0C0E);
  static const Color bgBottom = Color(0xFF0C0C0E);
  static const Color surface = Color(0xFF151518);
  static const Color surfaceAlt = Color(0xFF111114);
  static const Color line = Color(0xFF26262B);
  static const Color accent = Color(0xFF6B6BFF);
  static const Color onAccent = Color(0xFFFFFFFF);
  static const Color hot = Color(0xFFFF5B3A);
  static const Color coin = Color(0xFFFFB020);
  static const Color cream = Color(0xFFF4F4F0);
  static const Color gold = accent;
  static const Color goldDark = Color(0xFF5252E0);
  static const Color teal = Color(0xFF6EE7D8);
  static const Color muted = Color(0xFF8E8E96);
  static const Color deepPurple = Color(0xFF0C0C0E);
  static const Color cardPurple = surface;
  static const Color cardPurpleDark = surfaceAlt;

  /// Condensed display font. Falls back to the default font until the
  /// font files are bundled.
  static const String displayFont = 'BarlowCondensed';

  static TextStyle display(
    double size, {
    Color color = cream,
    double letterSpacing = 0,
  }) => TextStyle(
    fontFamily: displayFont,
    fontSize: size,
    height: 1,
    fontWeight: FontWeight.w800,
    letterSpacing: letterSpacing,
    color: color,
  );

  static const TextStyle label = TextStyle(
    color: muted,
    fontSize: 11,
    letterSpacing: 1.6,
    fontWeight: FontWeight.w700,
  );

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
    stdout.writeln('⏭️  Pehle se applied (onboarding-theme-v3). Kuch nahi badla.');
    return;
  }

  const anchor = 'abstract final class OnboardingTheme {';
  final start = src.indexOf(anchor);
  if (start < 0) {
    stdout.writeln('❌ OnboardingTheme class nahi mili.');
    exit(1);
  }
  final close = _matchBrace(src, start + anchor.length - 1);
  if (close < 0) {
    stdout.writeln('❌ Class ka closing brace match nahi hua.');
    exit(1);
  }
  stdout.writeln('✅ OnboardingTheme class mili (${close + 1 - start} chars)');

  src = src.replaceRange(start, close + 1, replacement);
  stdout.writeln('✅ FitGenie palette + display()/label helpers lage');

  if (dry) {
    stdout.writeln('🔍 --dry: file nahi likhi.');
    return;
  }

  final home = Platform.environment['HOME'] ?? '.';
  final dir = Directory('$home/clearway_backups')..createSync(recursive: true);
  final backup =
      '${dir.path}/onboarding_theme_${DateTime.now().millisecondsSinceEpoch}.dart';
  file.copySync(backup);
  stdout.writeln('✅ Backup: $backup');

  file.writeAsStringSync(src);
  stdout.writeln('✅ $path likh di.');
}

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
