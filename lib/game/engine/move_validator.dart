import 'game_level.dart';
import 'grid_point.dart';
import 'vehicle.dart';

enum BlockKind { vehicle, cone, oneWayGate, convoyPartner }

final class MoveCheck {
  const MoveCheck.clear({this.groupIds = const []})
    : canEscape = true,
      blockerId = null,
      blockKind = null,
      blockerCell = null;

  const MoveCheck.blocked(
    this.blockerId, {
    this.blockKind = BlockKind.vehicle,
    this.blockerCell,
    this.groupIds = const [],
  }) : canEscape = false;

  final bool canEscape;

  /// Id of the blocking vehicle. Null for cones and gates (see [blockerCell]).
  final String? blockerId;
  final BlockKind? blockKind;

  /// The cell of the blocking vehicle part, cone or gate.
  final GridPoint? blockerCell;

  /// Every vehicle that moves (or fails) together: just the tapped vehicle,
  /// or both vehicles of a convoy. The tapped vehicle is always first.
  final List<String> groupIds;
}

class _Block {
  const _Block(this.id, this.kind, this.cell);

  final String? id;
  final BlockKind kind;
  final GridPoint cell;
}

/// Pure movement rules shared by gameplay and level verification.
abstract final class MoveValidator {
  static MoveCheck check(
    GameLevel level,
    Iterable<Vehicle> remaining,
    Vehicle moving,
  ) {
    final present = remaining.toList(growable: false);
    return _check(level, present, _occupancy(present), moving);
  }

  /// Every occupied cell -> id of the vehicle on it. Built once per board
  /// state, so checking all vehicles stays linear in the number of cells.
  static Map<GridPoint, String> _occupancy(List<Vehicle> present) {
    final occupied = <GridPoint, String>{};
    for (final vehicle in present) {
      for (final cell in vehicle.cells) {
        occupied[cell] = vehicle.id;
      }
    }
    return occupied;
  }

  static MoveCheck _check(
    GameLevel level,
    List<Vehicle> present,
    Map<GridPoint, String> occupied,
    Vehicle moving,
  ) {
    final group = _groupOf(present, moving);
    final groupIds = group.map((vehicle) => vehicle.id).toList(growable: false);
    final ignore = groupIds.toSet();

    // The tapped vehicle is checked first so its own blocker wins the message.
    for (final member in group) {
      final block = _firstBlock(level, occupied, ignore, member);
      if (block == null) continue;
      final isPartner = member.id != moving.id;
      return MoveCheck.blocked(
        block.id,
        blockKind: isPartner ? BlockKind.convoyPartner : block.kind,
        blockerCell: block.cell,
        groupIds: groupIds,
      );
    }
    return MoveCheck.clear(groupIds: groupIds);
  }

  static List<Vehicle> safeVehicles(
    GameLevel level,
    Iterable<Vehicle> remaining,
  ) {
    final vehicles = remaining.toList(growable: false);
    final occupied = _occupancy(vehicles);
    return vehicles
        .where((vehicle) => _check(level, vehicles, occupied, vehicle).canEscape)
        .toList(growable: false);
  }

  static List<Vehicle> _groupOf(List<Vehicle> present, Vehicle moving) {
    final convoyId = moving.convoyId;
    if (convoyId == null) return [moving];
    return [
      moving,
      for (final vehicle in present)
        if (vehicle.convoyId == convoyId && vehicle.id != moving.id) vehicle,
    ];
  }

  static _Block? _firstBlock(
    GameLevel level,
    Map<GridPoint, String> occupied,
    Set<String> ignore,
    Vehicle vehicle,
  ) {
    var cursor = vehicle.head + vehicle.direction.step;
    while (level.contains(cursor)) {
      final blocker = occupied[cursor];
      if (blocker != null && !ignore.contains(blocker)) {
        return _Block(blocker, BlockKind.vehicle, cursor);
      }
      if (level.hasCone(cursor)) return _Block(null, BlockKind.cone, cursor);
      final gate = level.gateAt(cursor);
      if (gate != null && gate.direction != vehicle.direction) {
        return _Block(null, BlockKind.oneWayGate, cursor);
      }
      cursor += vehicle.direction.step;
    }
    return null;
  }
}
