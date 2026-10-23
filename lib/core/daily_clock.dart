import 'dart:convert';

import 'package:crypto/crypto.dart';

typedef DateTimeClock = DateTime Function();

/// Shared UTC day, countdown and deterministic seed helpers for daily puzzles.
abstract final class DailyClock {
  static String dayKey({DateTimeClock? clock}) {
    final now = (clock ?? DateTime.now)().toUtc();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  static DateTime utcNow({DateTimeClock? clock}) =>
      (clock ?? DateTime.now)().toUtc();

  static Duration untilNextUtcDay({DateTimeClock? clock}) {
    final now = utcNow(clock: clock);
    final nextDay = DateTime.utc(now.year, now.month, now.day + 1);
    return nextDay.difference(now);
  }

  static String countdownLabel({DateTimeClock? clock}) {
    final seconds = untilNextUtcDay(clock: clock).inSeconds;
    final minutes = (seconds + 59) ~/ 60;
    final hoursPart = minutes ~/ 60;
    final minutesPart = minutes % 60;
    return '${hoursPart.toString().padLeft(2, '0')}:'
        '${minutesPart.toString().padLeft(2, '0')}';
  }

  /// First SHA-256 word for `clearway:<UTC day key>`, interpreted big-endian.
  static int seedFor(String dayKey) {
    final digest = sha256.convert(utf8.encode('clearway:$dayKey')).bytes;
    return (digest[0] << 24) | (digest[1] << 16) | (digest[2] << 8) | digest[3];
  }
}
