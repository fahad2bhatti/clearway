import 'package:clearway/game/engine/game_level.dart';
import 'package:clearway/game/engine/grid_point.dart';
import 'package:clearway/game/engine/vehicle.dart';
import 'package:clearway/game/grid_assist.dart';
import 'package:flutter_test/flutter_test.dart';

// "a" points right and is blocked by "b"; "b" points up and can leave.
GameLevel _level() => GameLevel(
  number: 1,
  title: 'assist',
  width: 4,
  height: 2,
  vehicles: [
    Vehicle(
      id: 'a',
      type: VehicleType.bus,
      direction: TravelDirection.right,
      cells: const [GridPoint(0, 1), GridPoint(0, 0)],
      head: const GridPoint(0, 1),
    ),
    Vehicle(
      id: 'b',
      type: VehicleType.bus,
      direction: TravelDirection.up,
      cells: const [GridPoint(0, 3), GridPoint(1, 3)],
      head: const GridPoint(0, 3),
    ),
  ],
);

void main() {
  test('the first use is free, later uses are not', () {
    final assist = GridAssist();
    expect(assist.nextUseIsFree, isTrue);
    assist.turnOn();
    expect(assist.active, isTrue);
    expect(assist.nextUseIsFree, isFalse);
    assist.turnOff();
    expect(assist.active, isFalse);
    expect(assist.nextUseIsFree, isFalse);
  });

  test('nothing is highlighted while the assist is off', () {
    final level = _level();
    expect(GridAssist().highlight(level, level.vehicles), isEmpty);
  });

  test('the highlight follows the board after every move and undo', () {
    final level = _level();
    final assist = GridAssist()..turnOn();

    expect(assist.highlight(level, level.vehicles), {'b'});

    final afterMove = [level.vehicles.first];
    expect(assist.highlight(level, afterMove), {'a'});

    expect(assist.highlight(level, level.vehicles), {'b'});
  });

  test('its state survives a save and restore', () {
    final restored = GridAssist.fromJson((GridAssist()..turnOn()).toJson());
    expect(restored.active, isTrue);
    expect(restored.nextUseIsFree, isFalse);

    final fresh = GridAssist.fromJson(GridAssist().toJson());
    expect(fresh.active, isFalse);
    expect(fresh.nextUseIsFree, isTrue);
  });

  test('a save without assist fields restores a fresh assist', () {
    final restored = GridAssist.fromJson(const {});
    expect(restored.active, isFalse);
    expect(restored.nextUseIsFree, isTrue);
  });
}
