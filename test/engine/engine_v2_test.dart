import 'package:clearway/game/engine/game_level.dart';
import 'package:clearway/game/engine/grid_point.dart';
import 'package:clearway/game/engine/level_solver.dart';
import 'package:clearway/game/engine/move_validator.dart';
import 'package:clearway/game/engine/vehicle.dart';
import 'package:flutter_test/flutter_test.dart';

Vehicle _vehicle(
  String id,
  TravelDirection direction,
  int headRow,
  int headColumn, {
  int length = 2,
  String? convoy,
}) {
  final head = GridPoint(headRow, headColumn);
  return Vehicle(
    id: id,
    type: VehicleType.truck,
    direction: direction,
    head: head,
    convoyId: convoy,
    cells: List.generate(
      length,
      (i) => GridPoint(
        headRow - direction.rowStep * i,
        headColumn - direction.columnStep * i,
      ),
    ),
  );
}

GameLevel _level(
  List<Vehicle> vehicles, {
  List<GridPoint> cones = const [],
  List<OneWayGate> gates = const [],
}) => GameLevel(
  number: 1,
  title: 'test',
  width: 6,
  height: 6,
  vehicles: vehicles,
  cones: cones,
  gates: gates,
);

void main() {
  group('cone', () {
    test('blocks a vehicle and reports the cone cell', () {
      final truck = _vehicle('a', TravelDirection.right, 1, 1);
      final level = _level([truck], cones: [const GridPoint(1, 4)]);
      final result = MoveValidator.check(level, level.vehicles, truck);
      expect(result.canEscape, isFalse);
      expect(result.blockKind, BlockKind.cone);
      expect(result.blockerId, isNull);
      expect(result.blockerCell, const GridPoint(1, 4));
    });

    test('does not block a vehicle going another way', () {
      final truck = _vehicle('a', TravelDirection.left, 1, 1);
      final level = _level([truck], cones: [const GridPoint(1, 4)]);
      expect(
        MoveValidator.check(level, level.vehicles, truck).canEscape,
        isTrue,
      );
    });

    test('a permanent cone makes the level unsolvable', () {
      final truck = _vehicle('a', TravelDirection.right, 1, 1);
      final level = _level([truck], cones: [const GridPoint(1, 4)]);
      expect(LevelSolver.isSolvable(level), isFalse);
    });
  });

  group('one-way gate', () {
    test('blocks when travelling against the gate', () {
      final truck = _vehicle('a', TravelDirection.right, 1, 1);
      final level = _level(
        [truck],
        gates: [const OneWayGate(GridPoint(1, 3), TravelDirection.left)],
      );
      final result = MoveValidator.check(level, level.vehicles, truck);
      expect(result.canEscape, isFalse);
      expect(result.blockKind, BlockKind.oneWayGate);
      expect(result.blockerCell, const GridPoint(1, 3));
    });

    test('lets a vehicle through in the gate direction', () {
      final truck = _vehicle('a', TravelDirection.right, 1, 1);
      final level = _level(
        [truck],
        gates: [const OneWayGate(GridPoint(1, 3), TravelDirection.right)],
      );
      expect(
        MoveValidator.check(level, level.vehicles, truck).canEscape,
        isTrue,
      );
    });
  });

  group('convoy', () {
    // a and b are a pair. d sits in b's path, so tapping a must fail.
    List<Vehicle> pair({bool withBlocker = true}) => [
      _vehicle('a', TravelDirection.right, 0, 1, convoy: 'c'),
      _vehicle('b', TravelDirection.right, 2, 1, convoy: 'c'),
      if (withBlocker) _vehicle('d', TravelDirection.up, 2, 3),
    ];

    test('fails when the partner is blocked', () {
      final vehicles = pair();
      final level = _level(vehicles);
      final result = MoveValidator.check(level, vehicles, vehicles.first);
      expect(result.canEscape, isFalse);
      expect(result.blockKind, BlockKind.convoyPartner);
      expect(result.blockerId, 'd');
      expect(result.groupIds, ['a', 'b']);
    });

    test('moves both when both paths are clear', () {
      final vehicles = pair(withBlocker: false);
      final level = _level(vehicles);
      final result = MoveValidator.check(level, vehicles, vehicles.first);
      expect(result.canEscape, isTrue);
      expect(result.groupIds, ['a', 'b']);
    });

    test('solver counts a convoy as one move', () {
      final level = _level(pair());
      expect(LevelSolver.solve(level), ['d', 'a']);
    });

    test('level rejects a convoy with a single member', () {
      expect(
        () => _level([_vehicle('a', TravelDirection.right, 0, 1, convoy: 'c')]),
        throwsArgumentError,
      );
    });
  });

  test('level rejects a cone sitting on a vehicle', () {
    expect(
      () => _level(
        [_vehicle('a', TravelDirection.right, 1, 1)],
        cones: [const GridPoint(1, 0)],
      ),
      throwsArgumentError,
    );
  });
}
