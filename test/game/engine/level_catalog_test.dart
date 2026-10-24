import 'package:flutter_test/flutter_test.dart';

import 'package:clearway/game/data/level_catalog.dart';
import 'package:clearway/game/engine/game_level.dart';
import 'package:clearway/game/engine/level_solver.dart';

String _fingerprint(GameLevel level) =>
    [for (final v in level.vehicles) '${v.id}:${v.direction.name}:${v.cells}']
        .join('|');

void main() {
  group('maze level catalog', () {
    test('all catalog levels are deterministic and solvable', () {
      for (var number = 1; number <= LevelCatalog.totalLevels; number++) {
        final level = LevelCatalog.getLevel(number);
        expect(level.number, number);
        expect(level.chapter, LevelCatalog.chapterFor(number));
        expect(
          LevelSolver.isSolvable(level),
          isTrue,
          reason: 'Level $number is deadlocked.',
        );
      }
    });

    test('getLevel returns a cached instance', () {
      expect(
        identical(LevelCatalog.getLevel(12), LevelCatalog.getLevel(12)),
        isTrue,
      );
    });

    test('chapters change every ten levels', () {
      expect(LevelCatalog.chapterFor(1), 'Lahore');
      expect(LevelCatalog.chapterFor(10), 'Lahore');
      expect(LevelCatalog.chapterFor(11), 'Karachi');
    });

    test('the first levels are small tutorials that need an order', () {
      for (var number = 1; number <= 3; number++) {
        final level = LevelCatalog.getLevel(number);
        final report = LevelSolver.analyze(level)!;
        expect(level.vehicles.length, number + 1);
        expect(report.initiallyFree, greaterThanOrEqualTo(1));
        if (number >= 2) expect(report.rounds, greaterThanOrEqualTo(2));
      }
    });

    test('bus count grows through the progression', () {
      int buses(int n) => LevelCatalog.getLevel(n).vehicles.length;
      expect(buses(4), lessThanOrEqualTo(buses(20)));
      expect(buses(20), lessThanOrEqualTo(buses(60)));
      expect(buses(80), greaterThanOrEqualTo(70));
    });

    test('boss levels are silhouette shaped', () {
      for (final number in [10, 20, 30, 40, 50, 60, 70, 80]) {
        final level = LevelCatalog.getLevel(number);
        expect(level.boss, isTrue);
        expect(level.shape, isNotNull);
      }
    });
  });

  group('daily board', () {
    test('is date-seeded, uses Rush Hour, has 100 buses and is solvable', () {
      final first = LevelCatalog.daily('2026-10-23');
      final sameDay = LevelCatalog.daily('2026-10-23');
      final nextDay = LevelCatalog.daily('2026-10-24');

      expect(first.chapter, 'Rush Hour');
      expect(first.vehicles, hasLength(100));
      expect(LevelSolver.isSolvable(first), isTrue);
      expect(_fingerprint(sameDay), _fingerprint(first));
      expect(_fingerprint(nextDay), isNot(_fingerprint(first)));
    });

    test('a server seed overrides the date seed', () {
      final seeded = LevelCatalog.daily('2026-10-23', serverSeed: 12345);
      expect(
        _fingerprint(LevelCatalog.daily('2026-10-24', serverSeed: 12345)),
        _fingerprint(seeded),
      );
    });

    test('30 consecutive days are solvable with 100 buses', () {
      for (var day = 1; day <= 30; day++) {
        final dayKey = '2026-11-${day.toString().padLeft(2, '0')}';
        final level = LevelCatalog.daily(dayKey);
        expect(level.vehicles, hasLength(100), reason: dayKey);
        expect(LevelSolver.isSolvable(level), isTrue, reason: dayKey);
      }
    });
  });
}
