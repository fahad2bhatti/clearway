import 'package:flutter_test/flutter_test.dart';

import 'package:clearway/game/data/level_catalog.dart';
import 'package:clearway/game/engine/level_solver.dart';
import 'package:clearway/game/engine/move_validator.dart';

void main() {
  group('Clearway level catalog', () {
    test('ships 80 deterministic levels', () {
      expect(LevelCatalog.levels, hasLength(80));
      expect(
        LevelCatalog.levels.map((level) => level.number),
        List<int>.generate(80, (i) => i + 1),
      );
    });

    test('every shipped board is solvable', () {
      for (final level in LevelCatalog.levels) {
        expect(
          LevelSolver.isSolvable(level),
          isTrue,
          reason: 'Level ${level.number} is deadlocked.',
        );
      }
    });

    test('solver returns a complete legal removal order for each board', () {
      for (final level in LevelCatalog.levels) {
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

    test('level two starts with one safe vehicle and one blocked truck', () {
      final level = LevelCatalog.levels[1];
      final truck = level.vehicles.first;
      final result = MoveValidator.check(level, level.vehicles, truck);

      expect(result.canEscape, isFalse);
      expect(result.blockerId, level.vehicles[1].id);
      expect(
        MoveValidator.safeVehicles(level, level.vehicles).map((v) => v.id),
        contains(level.vehicles[1].id),
      );
    });

    test('an escaped vehicle does not block the next move', () {
      final level = LevelCatalog.levels[1];
      final truck = level.vehicles.first;
      final remaining = level.vehicles.where(
        (vehicle) => vehicle != level.vehicles[1],
      );

      expect(MoveValidator.check(level, remaining, truck).canEscape, isTrue);
    });
  });
}
