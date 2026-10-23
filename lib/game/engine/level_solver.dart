import 'game_level.dart';
import 'move_validator.dart';
import 'vehicle.dart';

/// Remove-only puzzle solver. A bit mask memo keeps boards fast.
/// A convoy pair counts as ONE move that removes both vehicles.
abstract final class LevelSolver {
  static const maxVehicles = 62;

  static bool isSolvable(GameLevel level) {
    if (level.vehicles.length > maxVehicles) {
      throw ArgumentError('The solver supports at most $maxVehicles vehicles.');
    }
    return _search(level) != null;
  }

  /// Returns the tapped vehicle ids in order, or null if unsolvable.
  static List<String>? solve(GameLevel level) {
    if (level.vehicles.length > maxVehicles) return null;
    return _search(level);
  }

  static List<String>? _search(GameLevel level) {
    final vehicles = level.vehicles;
    final indexOf = {
      for (var i = 0; i < vehicles.length; i++) vehicles[i].id: i,
    };

    // For each vehicle: the mask of everything removed when it is tapped.
    final removeMask = List<int>.filled(vehicles.length, 0);
    for (var i = 0; i < vehicles.length; i++) {
      final convoyId = vehicles[i].convoyId;
      var mask = 1 << i;
      if (convoyId != null) {
        for (var j = 0; j < vehicles.length; j++) {
          if (vehicles[j].convoyId == convoyId) mask |= 1 << j;
        }
      }
      removeMask[i] = mask;
    }

    final failed = <int>{};

    List<String>? visit(int mask) {
      if (mask == 0) return const [];
      if (!failed.add(mask)) return null;
      final remaining = <Vehicle>[];
      for (var index = 0; index < vehicles.length; index++) {
        if ((mask & (1 << index)) != 0) remaining.add(vehicles[index]);
      }
      final tried = <int>{};
      for (final vehicle in MoveValidator.safeVehicles(level, remaining)) {
        final remove = removeMask[indexOf[vehicle.id]!];
        if (!tried.add(remove)) continue;
        final suffix = visit(mask & ~remove);
        if (suffix != null) return [vehicle.id, ...suffix];
      }
      return null;
    }

    return visit((1 << vehicles.length) - 1);
  }
}
