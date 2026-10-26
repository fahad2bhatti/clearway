import 'package:clearway/game/engine/game_level.dart';
import 'package:clearway/game/engine/grid_point.dart';
import 'package:clearway/game/engine/level_solver.dart';
import 'package:clearway/game/engine/vehicle.dart';
import 'package:clearway/game/generator/board_shapes.dart';
import 'package:clearway/game/generator/maze_level_generator.dart';
import 'package:clearway/game/generator/seeded_random.dart';
import 'package:flutter_test/flutter_test.dart';

String _fingerprint(GameLevel level) => [
  '${level.width}x${level.height}',
  for (final v in level.vehicles) '${v.id}:${v.direction.name}:${v.cells}',
].join('|');

bool _hasBend(Vehicle vehicle) {
  for (var i = 2; i < vehicle.cells.length; i++) {
    final a = vehicle.cells[i - 2];
    final b = vehicle.cells[i - 1];
    final c = vehicle.cells[i];
    if (b.row - a.row != c.row - b.row ||
        b.column - a.column != c.column - b.column) {
      return true;
    }
  }
  return false;
}

void main() {
  group('SeededRandom', () {
    test('same seed gives the same sequence', () {
      final a = SeededRandom(42);
      final b = SeededRandom(42);
      expect(
        [for (var i = 0; i < 20; i++) a.nextInt(1000)],
        [for (var i = 0; i < 20; i++) b.nextInt(1000)],
      );
    });

    test('different seeds give different sequences', () {
      final a = SeededRandom(1);
      final b = SeededRandom(2);
      expect([
        for (var i = 0; i < 10; i++) a.nextInt32(),
      ], isNot([for (var i = 0; i < 10; i++) b.nextInt32()]));
    });
  });

  group('board shapes', () {
    test('every shape has cells and fits its box', () {
      for (final kind in BoardShapeKind.values) {
        final cells = BoardShapes.cells(kind, 20, 20);
        expect(cells.isNotEmpty, isTrue, reason: '$kind');
        expect(
          cells.every(
            (c) => c.row >= 0 && c.row < 20 && c.column >= 0 && c.column < 20,
          ),
          isTrue,
        );
      }
      expect(BoardShapes.cells(BoardShapeKind.rectangle, 6, 6), hasLength(36));
    });
  });

  group('solver', () {
    test('two buses facing each other are a deadlock', () {
      Vehicle bus(String id, TravelDirection d, int row, int col, int tail) =>
          Vehicle(
            id: id,
            type: VehicleType.bus,
            direction: d,
            head: GridPoint(row, col),
            cells: [GridPoint(row, col), GridPoint(row, tail)],
          );
      final level = GameLevel(
        number: 1,
        title: 'deadlock',
        width: 4,
        height: 2,
        vehicles: [
          bus('a', TravelDirection.right, 0, 1, 0),
          bus('b', TravelDirection.left, 0, 2, 3),
        ],
      );
      expect(LevelSolver.isSolvable(level), isFalse);
      expect(LevelSolver.solve(level), isNull);
    });
  });

  group('maze levels', () {
    test('levels 1 to 120 are solvable, complete and deterministic', () {
      for (var n = 1; n <= 120; n++) {
        final level = MazeLevelGenerator.generate(n);
        final spec = MazeLevelGenerator.specFor(n);
        final report = LevelSolver.analyze(level);
        expect(report, isNotNull, reason: 'level $n is not solvable');
        expect(
          level.vehicles.length,
          greaterThanOrEqualTo(spec.buses),
          reason: 'level $n',
        );
        expect(
          report!.taps,
          hasLength(level.vehicles.length),
          reason: 'level $n',
        );
        expect(
          _fingerprint(MazeLevelGenerator.generate(n)),
          _fingerprint(level),
          reason: 'level $n changes between runs',
        );
      }
    });

    test('boards are filled: few empty cells (levels 4 to 80)', () {
      final tooEmpty = <String>[];
      for (var n = 4; n <= 80; n++) {
        final level = MazeLevelGenerator.generate(n);
        final cells = level.shape!;
        final covered = {for (final v in level.vehicles) ...v.cells};
        final empty = cells.where((c) => !covered.contains(c)).length;
        if (empty > 4) tooEmpty.add('level $n: $empty empty');
      }
      expect(tooEmpty, isEmpty);
    });

    test('only buses, no cones, gates or convoys', () {
      for (final n in [1, 10, 25, 40, 80]) {
        final level = MazeLevelGenerator.generate(n);
        expect(level.cones, isEmpty);
        expect(level.gates, isEmpty);
        expect(level.vehicles.every((v) => v.type == VehicleType.bus), isTrue);
        expect(level.vehicles.every((v) => v.convoyId == null), isTrue);
      }
    });

    test('the cell behind each head continues its direction', () {
      for (final n in [2, 20, 60]) {
        for (final v in MazeLevelGenerator.generate(n).vehicles) {
          final behind = GridPoint(
            v.head.row - v.direction.rowStep,
            v.head.column - v.direction.columnStep,
          );
          expect(v.cells[1], behind, reason: '${v.id} of level $n');
        }
      }
    });

    test('bus count grows with the level number', () {
      int buses(int n) => MazeLevelGenerator.generate(n).vehicles.length;
      expect(buses(1), lessThanOrEqualTo(buses(4)));
      expect(buses(4), lessThanOrEqualTo(buses(20)));
      expect(buses(20), lessThanOrEqualTo(buses(60)));
      expect(buses(60), lessThanOrEqualTo(buses(80)));
      expect(buses(80), greaterThanOrEqualTo(70));
      // A monster level (every 5th) is heavier than the level before it.
      expect(buses(15), greaterThan(buses(14)));
      expect(buses(21), greaterThan(buses(10)));
    });

    test('later levels have curved buses', () {
      final level = MazeLevelGenerator.generate(40);
      expect(level.vehicles.where(_hasBend).length, greaterThanOrEqualTo(5));
    });

    test('later levels need real planning', () {
      final report = LevelSolver.analyze(MazeLevelGenerator.generate(40))!;
      expect(report.rounds, greaterThanOrEqualTo(6));
      expect(report.initiallyFree, lessThanOrEqualTo(report.taps.length ~/ 2));
    });

    test('every 5th level from level 5 is a monster level', () {
      for (var n = 1; n <= 80; n++) {
        expect(
          MazeLevelGenerator.specFor(n).boss,
          n >= 5 && n % 5 == 0,
          reason: 'level $n',
        );
      }
      final normal = MazeLevelGenerator.specFor(14).buses;
      final monster = MazeLevelGenerator.specFor(15).buses;
      expect(monster, greaterThan(normal * 1.3));
    });

    test('arrow count steps up every 10 levels', () {
      int buses(int n) => MazeLevelGenerator.specFor(n).buses;
      expect(buses(11), greaterThan(buses(9)));
      expect(buses(21), greaterThan(buses(19)));
      expect(buses(31), greaterThan(buses(29)));
    });

    test('boss levels are silhouette shaped and keep buses inside', () {
      for (final n in [10, 20, 30, 40]) {
        final level = MazeLevelGenerator.generate(n);
        expect(level.boss, isTrue);
        expect(level.shape, isNotNull);
        expect(
          level.vehicles.every((v) => v.cells.every(level.shape!.contains)),
          isTrue,
        );
      }
    });
  });

  group('daily maze', () {
    test('has 100 buses, is solvable and is the same for the same date', () {
      final level = MazeLevelGenerator.generateDaily(20261024);
      expect(level.vehicles, hasLength(100));
      expect(level.title, 'Rush Hour');
      expect(LevelSolver.isSolvable(level), isTrue);
      expect(
        _fingerprint(MazeLevelGenerator.generateDaily(20261024)),
        _fingerprint(level),
      );
    });

    test('a different date gives a different board', () {
      expect(
        _fingerprint(MazeLevelGenerator.generateDaily(20261025)),
        isNot(_fingerprint(MazeLevelGenerator.generateDaily(20261024))),
      );
    });

    test('30 consecutive days are all solvable with 100 buses', () {
      for (var day = 1; day <= 30; day++) {
        final level = MazeLevelGenerator.generateDaily(20261100 + day);
        expect(level.vehicles, hasLength(100), reason: 'day $day');
        expect(LevelSolver.isSolvable(level), isTrue, reason: 'day $day');
      }
    });
  });
}
