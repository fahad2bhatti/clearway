import 'package:flutter_test/flutter_test.dart';
import 'package:clearway/game/data/level_catalog.dart';
import 'package:clearway/game/engine/level_solver.dart';
import 'package:clearway/game/engine/move_validator.dart';
import 'package:clearway/game/engine/vehicle.dart';
import 'package:clearway/core/daily_clock.dart';

void main() {
  group('browser level progression port', () {
    test('all catalog levels are deterministic and solvable', () {
      for (var number = 1; number <= LevelCatalog.totalLevels; number++) {
        final level = LevelCatalog.getLevel(number);
        expect(
          LevelSolver.isSolvable(level),
          isTrue,
          reason: 'level ${level.number}',
        );
        final regenerated = LevelCatalog.getLevel(level.number);
        expect(identical(level, regenerated), isTrue);
        expect(
          regenerated.vehicles.map((v) => v.cells.toString()).toList(),
          level.vehicles.map((v) => v.cells.toString()).toList(),
        );
      }
    });

    test('getLevel returns a cached instance', () {
      final first = LevelCatalog.getLevel(12);
      final second = LevelCatalog.getLevel(12);

      expect(identical(first, second), isTrue);
    });

    test('mechanics unlock in the progression', () {
      expect(LevelCatalog.getLevel(10).cones, isNotEmpty);
      expect(LevelCatalog.getLevel(25).gates, isNotEmpty);
      final level40 = LevelCatalog.getLevel(40);
      final crossingBuses = level40.vehicles.take(2).toList();
      expect(
        crossingBuses.every((vehicle) => vehicle.type == VehicleType.bus),
        isTrue,
      );
      expect(crossingBuses.map((vehicle) => vehicle.convoyId), [null, null]);
      expect(crossingBuses[0].direction, isNot(crossingBuses[1].direction));
      // The buses cross each other's exit lanes: at least one of them starts
      // blocked by the other (either direction), so order matters.
      final firstCheck = MoveValidator.check(
        level40,
        level40.vehicles,
        crossingBuses[0],
      );
      final secondCheck = MoveValidator.check(
        level40,
        level40.vehicles,
        crossingBuses[1],
      );
      expect(
        firstCheck.blockerId == crossingBuses[1].id ||
            secondCheck.blockerId == crossingBuses[0].id,
        isTrue,
      );
      expect(
        LevelCatalog.getLevel(50).vehicles.where((v) => v.convoyId != null),
        hasLength(2),
      );
    });

    test('daily board is date-seeded, uses Rush Hour, and is solvable', () {
      final first = LevelCatalog.daily('2026-10-23');
      final sameDay = LevelCatalog.daily('2026-10-23');
      final nextDay = LevelCatalog.daily('2026-10-24');
      expect(first.chapter, 'Rush Hour');
      expect(
        first.vehicles.map((v) => v.cells.toString()).toList(),
        sameDay.vehicles.map((v) => v.cells.toString()).toList(),
      );
      expect(
        nextDay.vehicles.map((v) => v.cells.toString()).toList(),
        isNot(first.vehicles.map((v) => v.cells.toString()).toList()),
      );
      expect(LevelSolver.isSolvable(first), isTrue);
    });

    test('daily levels stay solvable for 365 consecutive UTC days', () {
      final firstDay = DateTime.utc(2026, 1, 1);
      for (var offset = 0; offset < 365; offset++) {
        final date = firstDay.add(Duration(days: offset));
        final dayKey = DailyClock.dayKey(clock: () => date);
        final level = LevelCatalog.daily(dayKey);
        expect(
          LevelSolver.isSolvable(level),
          isTrue,
          reason: 'Daily level for $dayKey is not solvable.',
        );
      }
    });
  });
}
