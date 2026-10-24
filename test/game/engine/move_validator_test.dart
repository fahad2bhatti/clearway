import 'package:flutter_test/flutter_test.dart';

import 'package:clearway/game/data/level_catalog.dart';
import 'package:clearway/game/engine/level_solver.dart';
import 'package:clearway/game/engine/move_validator.dart';

void main() {
  group('Clearway level catalog', () {
    test('ships the configured number of deterministic levels', () {
      expect(
        List<int>.generate(
          LevelCatalog.totalLevels,
          (i) => i + 1,
        ).map((number) => LevelCatalog.getLevel(number).number),
        List<int>.generate(LevelCatalog.totalLevels, (i) => i + 1),
      );
    });

    test('every shipped board is solvable', () {
      for (var number = 1; number <= LevelCatalog.totalLevels; number++) {
        final level = LevelCatalog.getLevel(number);
        expect(
          LevelSolver.isSolvable(level),
          isTrue,
          reason: 'Level ${level.number} is deadlocked.',
        );
      }
    });

    test('solver returns a complete legal removal order for each board', () {
      for (var number = 1; number <= LevelCatalog.totalLevels; number++) {
        final level = LevelCatalog.getLevel(number);
        final solution = LevelSolver.solve(level);
        expect(
          solution,
          isNotNull,
          reason: 'Level ${level.number} has no solution.',
        );
        expect(solution!.length, lessThanOrEqualTo(level.vehicles.length));

        final remaining = List.of(level.vehicles);
        for (final id in solution) {
          final vehicle = remaining.singleWhere((vehicle) => vehicle.id == id);
          final move = MoveValidator.check(level, remaining, vehicle);
          expect(move.canEscape, isTrue);
          remaining.removeWhere(
            (vehicle) => move.groupIds.contains(vehicle.id),
          );
        }
        expect(remaining, isEmpty);
      }
    });

    test(
      'level two has a free bus and a blocked bus that names its blocker',
      () {
        final level = LevelCatalog.getLevel(2);
        final blocked = level.vehicles
            .where(
              (v) => !MoveValidator.check(level, level.vehicles, v).canEscape,
            )
            .toList();

        expect(blocked, isNotEmpty);
        expect(MoveValidator.safeVehicles(level, level.vehicles), isNotEmpty);
        final result = MoveValidator.check(
          level,
          level.vehicles,
          blocked.first,
        );
        expect(level.vehicles.map((v) => v.id), contains(result.blockerId));
      },
    );

    test('an escaped bus does not block the next move', () {
      final level = LevelCatalog.getLevel(2);
      final blocked = level.vehicles.firstWhere(
        (v) => !MoveValidator.check(level, level.vehicles, v).canEscape,
      );
      final blockerId = MoveValidator.check(
        level,
        level.vehicles,
        blocked,
      ).blockerId;
      final remaining = level.vehicles
          .where((vehicle) => vehicle.id != blockerId)
          .toList();

      expect(
        MoveValidator.check(level, remaining, blocked).blockerId,
        isNot(blockerId),
      );
    });
  });
}
