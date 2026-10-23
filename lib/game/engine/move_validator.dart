import 'game_level.dart';
import 'grid_point.dart';
import 'vehicle.dart';

enum BlockKind { vehicle, cone, oneWayGate, convoyPartner }

final class MoveCheck {
  const MoveCheck.clear()
    : canEscape = true,
      blockerId = null,
      blockKind = null;

  const MoveCheck.blocked(this.blockerId, {this.blockKind = BlockKind.vehicle})
    : canEscape = false;

  final bool canEscape;
  final String? blockerId;
  final BlockKind? blockKind;
}

/// Pure movement rules shared by gameplay and level verification.
abstract final class MoveValidator {
  static MoveCheck check(
    GameLevel level,
    Iterable<Vehicle> remaining,
    Vehicle moving,
  ) {
    final occupied = <GridPoint, String>{};
    for (final vehicle in remaining) {
      if (vehicle.id == moving.id) continue;
      for (final cell in vehicle.cells) {
        occupied[cell] = vehicle.id;
      }
    }

    var cursor = moving.head + moving.direction.step;
    while (cursor.row >= 0 &&
        cursor.row < level.height &&
        cursor.column >= 0 &&
        cursor.column < level.width) {
      final blocker = occupied[cursor];
      if (blocker != null) return MoveCheck.blocked(blocker);
      cursor += moving.direction.step;
    }
    return const MoveCheck.clear();
  }

  static List<Vehicle> safeVehicles(
    GameLevel level,
    Iterable<Vehicle> remaining,
  ) {
    final vehicles = remaining.toList(growable: false);
    return vehicles
        .where((vehicle) => check(level, vehicles, vehicle).canEscape)
        .toList(growable: false);
  }
}
