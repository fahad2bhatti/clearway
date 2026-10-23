import 'package:flutter_test/flutter_test.dart';
import 'package:clearway/game/data/level_catalog.dart';
import 'package:clearway/game/engine/level_solver.dart';
import 'package:clearway/game/engine/vehicle.dart';

void main() {
  group('browser level progression port', () {
    test('all 80 levels are deterministic and solvable', () {
      expect(LevelCatalog.levels, hasLength(80));
      for (final level in LevelCatalog.levels) {
        expect(
          LevelSolver.isSolvable(level),
          isTrue,
          reason: 'level ${level.number}',
        );
        final regenerated = LevelCatalog.getLevel(level.number);
        expect(
          regenerated.vehicles.map((v) => v.cells.toString()).toList(),
          level.vehicles.map((v) => v.cells.toString()).toList(),
        );
      }
    });

    test('mechanics unlock in the progression', () {
      expect(LevelCatalog.getLevel(10).cones, isNotEmpty);
      expect(LevelCatalog.getLevel(25).gates, isNotEmpty);
      final crossingBuses = LevelCatalog.getLevel(40).vehicles.take(2).toList();
      expect(
        crossingBuses.every((vehicle) => vehicle.type == VehicleType.bus),
        isTrue,
      );
      expect(crossingBuses.map((vehicle) => vehicle.convoyId), [null, null]);
      expect(crossingBuses[0].direction, isNot(crossingBuses[1].direction));
      expect(
        crossingBuses[0].cells.contains(
          crossingBuses[1].head + crossingBuses[1].direction.step,
        ),
        isTrue,
      );
      expect(
        LevelCatalog.getLevel(50).vehicles.where((v) => v.convoyId != null),
        hasLength(2),
      );
    });

    test('daily board is date-seeded, uses Rush Hour, and is solvable', () {
      final first = LevelCatalog.daily(DateTime(2026, 10, 23));
      final sameDay = LevelCatalog.daily(DateTime(2026, 10, 23));
      expect(first.chapter, 'Rush Hour');
      expect(
        first.vehicles.map((v) => v.cells.toString()).toList(),
        sameDay.vehicles.map((v) => v.cells.toString()).toList(),
      );
      expect(LevelSolver.isSolvable(first), isTrue);
    });
  });
}
