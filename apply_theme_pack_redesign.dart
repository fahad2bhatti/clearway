// Run from the Clearway project root:
//   dart apply_theme_pack_redesign.dart --dry   (sirf check, file nahi likhta)
//   dart apply_theme_pack_redesign.dart         (patch apply)
import 'dart:io';

const marker = '// theme-v2';
const path = 'lib/app/theme_pack.dart';

const replacement = r'''static const arrowNight = ThemePack(
    // theme-v2
    id: 'arrow_night',
    name: 'Arrow night',
    asphalt: Color(0xff0b1020),
    yardSurface: Color(0xff111831),
    gridLine: Color(0xff252e4a),
    ivory: Color(0xfff2f4fa),
    panel: Color(0xff151d38),
    panelActive: Color(0xff1e2a4d),
    textMuted: Color(0xff9aa3bf),
    iconDisabled: Color(0xff5a6483),
    textDisabled: Color(0xff6b7595),
    accent: Color(0xff6ee7c8),
    floralMagenta: Color(0xffff5c8d),
    emerald: Color(0xff4ade80),
    turquoise: Color(0xff6ee7c8),
    coral: Color(0xffff796c),
    showFloralMotifs: false,
    vehicleNoun: 'arrow',
    emptyYardMessage: 'All clear!',
  );''';

void main(List<String> args) {
  final dry = args.contains('--dry');
  final file = File(path);
  if (!file.existsSync()) {
    stdout.writeln('❌ $path nahi mila. Project root se chalao.');
    exit(1);
  }
  var src = file.readAsStringSync();

  if (src.contains(marker)) {
    stdout.writeln('⏭️  Pehle se applied (theme-v2). Kuch nahi badla.');
    return;
  }

  const anchor = 'static const arrowNight = ThemePack(';
  final start = src.indexOf(anchor);
  if (start < 0) {
    stdout.writeln('❌ arrowNight block nahi mila. File badli hui hai?');
    exit(1);
  }
  final close = _matchParen(src, start + anchor.length - 1);
  if (close < 0) {
    stdout.writeln('❌ arrowNight ka closing bracket match nahi hua.');
    exit(1);
  }
  var end = close + 1;
  if (end < src.length && src[end] == ';') end++;
  stdout.writeln('✅ arrowNight block mila (${end - start} chars)');

  src = src.replaceRange(start, end, replacement);
  stdout.writeln('✅ Naye navy + mint rang lage, floral motifs off');

  if (src.contains('Purple "arrow night"')) {
    src = src.replaceFirst('Purple "arrow night"', 'Navy + mint "arrow night"');
    stdout.writeln('✅ Doc comment update kiya');
  } else {
    stdout.writeln('⚠️  Doc comment nahi mila, skip (koi masla nahi)');
  }

  if (dry) {
    stdout.writeln('🔍 --dry: file nahi likhi.');
    return;
  }

  final home = Platform.environment['HOME'] ?? '.';
  final dir = Directory('$home/clearway_backups')..createSync(recursive: true);
  final ts = DateTime.now().millisecondsSinceEpoch;
  final backup = '${dir.path}/theme_pack_$ts.dart';
  file.copySync(backup);
  stdout.writeln('✅ Backup: $backup');

  file.writeAsStringSync(src);
  stdout.writeln('✅ $path likh di. Ab: dart format $path && dart analyze');
}

/// Finds the matching ')' for the '(' at [open]. Skips strings and comments.
int _matchParen(String s, int open) {
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
    if (c == '(') depth++;
    if (c == ')') {
      depth--;
      if (depth == 0) return i;
    }
    i++;
  }
  return -1;
}
