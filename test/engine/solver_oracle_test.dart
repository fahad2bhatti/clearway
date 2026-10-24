import 'package:clearway/game/engine/game_level.dart';
import 'package:clearway/game/engine/grid_point.dart';
import 'package:clearway/game/engine/level_solver.dart';
import 'package:clearway/game/engine/move_validator.dart';
import 'package:clearway/game/engine/vehicle.dart';
import 'package:clearway/game/generator/seeded_random.dart';
import 'package:flutter_test/flutter_test.dart';

/// Independent, deliberately naive re-implementation of the movement rules.
bool _oracleEscapes(GameLevel level, List<Vehicle> remaining, Vehicle vehicle) {
  final group = vehicle.convoyId == null
      ? [vehicle]
      : remaining.where((v) => v.convoyId == vehicle.convoyId).toList();
  final groupIds = group.map((v) => v.id).toSet();
  final busy = <String>{
    for (final other in remaining)
      if (!groupIds.contains(other.id))
        for (final cell in other.cells) '${cell.row},${cell.column}',
  };
  for (final member in group) {
    var row = member.head.row + member.direction.rowStep;
    var column = member.head.column + member.direction.columnStep;
    while (row >= 0 &&
        row < level.height &&
        column >= 0 &&
        column < level.width) {
      if (busy.contains('$row,$column')) return false;
      if (level.cones.any((c) => c.row == row && c.column == column)) {
        return false;
      }
      for (final gate in level.gates) {
        if (gate.position.row == row &&
            gate.position.column == column &&
            gate.direction != member.direction) {
          return false;
        }
      }
      row += member.direction.rowStep;
      column += member.direction.columnStep;
    }
  }
  return true;
}

Set<String> _leavingWith(List<Vehicle> remaining, Vehicle vehicle) =>
    vehicle.convoyId == null
    ? {vehicle.id}
    : remaining
          .where((v) => v.convoyId == vehicle.convoyId)
          .map((v) => v.id)
          .toSet();

/// Exhaustive search over every removal order.
bool _bruteSolvable(
  GameLevel level,
  List<Vehicle> remaining,
  Map<String, bool> memo,
) {
  if (remaining.isEmpty) return true;
  final key = (remaining.map((v) => v.id).toList()..sort()).join('|');
  final cached = memo[key];
  if (cached != null) return cached;
  var solvable = false;
  for (final vehicle in remaining) {
    if (!_oracleEscapes(level, remaining, vehicle)) continue;
    final gone = _leavingWith(remaining, vehicle);
    final rest = remaining.where((v) => !gone.contains(v.id)).toList();
    if (_bruteSolvable(level, rest, memo)) {
      solvable = true;
      break;
    }
  }
  return memo[key] = solvable;
}

GameLevel? _randomLevel(SeededRandom rng) {
  final width = 3 + rng.nextInt(4);
  final height = 3 + rng.nextInt(4);
  final occupied = <GridPoint>{};
  final vehicles = <Vehicle>[];
  final wanted = 2 + rng.nextInt(6);
  for (var tries = 0; tries < wanted * 6 && vehicles.length < wanted; tries++) {
    final head = GridPoint(rng.nextInt(height), rng.nextInt(width));
    final direction = TravelDirection.values[rng.nextInt(4)];
    final length = 2 + rng.nextInt(2);
    final cells = <GridPoint>[head];
    var cursor = head;
    var fits = !occupied.contains(head);
    for (var i = 1; i < length && fits; i++) {
      cursor = GridPoint(
        cursor.row - direction.rowStep,
        cursor.column - direction.columnStep,
      );
      final inside =
          cursor.row >= 0 &&
          cursor.row < height &&
          cursor.column >= 0 &&
          cursor.column < width;
      if (!inside || occupied.contains(cursor)) {
        fits = false;
      } else {
        cells.add(cursor);
      }
    }
    if (!fits) continue;
    occupied.addAll(cells);
    vehicles.add(
      Vehicle(
        id: 'v${vehicles.length}',
        type: VehicleType.bus,
        direction: direction,
        cells: cells,
        head: head,
      ),
    );
  }
  if (vehicles.length < 2) return null;

  final free = [
    for (var r = 0; r < height; r++)
      for (var c = 0; c < width; c++)
        if (!occupied.contains(GridPoint(r, c))) GridPoint(r, c),
  ];
  rng.shuffle(free);
  final cones = <GridPoint>[];
  final gates = <OneWayGate>[];
  if (free.length > 2 && rng.chance(50)) cones.add(free.removeLast());
  if (free.length > 2 && rng.chance(50)) {
    gates.add(
      OneWayGate(free.removeLast(), TravelDirection.values[rng.nextInt(4)]),
    );
  }
  var finalVehicles = vehicles;
  if (vehicles.length >= 3 && rng.chance(40)) {
    finalVehicles = [
      for (var i = 0; i < vehicles.length; i++)
        i < 2
            ? Vehicle(
                id: vehicles[i].id,
                type: vehicles[i].type,
                direction: vehicles[i].direction,
                cells: vehicles[i].cells,
                head: vehicles[i].head,
                convoyId: 'c1',
              )
            : vehicles[i],
    ];
  }
  return GameLevel(
    number: 1,
    title: 'fuzz',
    width: width,
    height: height,
    vehicles: finalVehicles,
    cones: cones,
    gates: gates,
  );
}

void main() {
  test('MoveValidator and LevelSolver agree with a brute-force oracle', () {
    final rng = SeededRandom(2026);
    var boards = 0;
    var solvable = 0;
    for (var i = 0; i < 1500; i++) {
      final level = _randomLevel(rng);
      if (level == null) continue;
      boards++;

      for (final vehicle in level.vehicles) {
        expect(
          MoveValidator.check(level, level.vehicles, vehicle).canEscape,
          _oracleEscapes(level, level.vehicles, vehicle),
          reason: 'board $i vehicle ${vehicle.id}',
        );
      }

      final expected = _bruteSolvable(level, level.vehicles, {});
      expect(LevelSolver.isSolvable(level), expected, reason: 'board $i');
      if (!expected) continue;
      solvable++;

      // Replaying the solver's taps must be legal at every step.
      var remaining = level.vehicles.toList();
      for (final id in LevelSolver.solve(level)!) {
        final vehicle = remaining.firstWhere((v) => v.id == id);
        expect(
          _oracleEscapes(level, remaining, vehicle),
          isTrue,
          reason: 'board $i tap $id',
        );
        final gone = _leavingWith(remaining, vehicle);
        remaining = remaining.where((v) => !gone.contains(v.id)).toList();
      }
      expect(remaining, isEmpty, reason: 'board $i not cleared');
    }
    // The fuzzer must exercise both outcomes, or it proves nothing.
    expect(boards, greaterThan(1000));
    expect(solvable, greaterThan(300));
    expect(solvable, lessThan(boards));
  });
}
