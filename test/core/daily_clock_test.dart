import 'package:clearway/core/daily_clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DailyClock', () {
    test('converts injected local time to a UTC day key', () {
      final key = DailyClock.dayKey(
        clock: () => DateTime.parse('2026-10-24T01:30:00+05:00'),
      );

      expect(key, '2026-10-23');
    });

    test('formats countdown to the next UTC midnight', () {
      final label = DailyClock.countdownLabel(
        clock: () => DateTime.utc(2026, 10, 24, 23, 30),
      );

      expect(label, '00:30');
    });

    test('matches shared client/server SHA-256 seed vectors', () {
      expect(DailyClock.seedFor('2026-10-24'), 4006804975);
      expect(DailyClock.seedFor('2026-01-01'), 4082560732);
      expect(DailyClock.seedFor('2027-02-28'), 1737354936);
    });
  });
}
