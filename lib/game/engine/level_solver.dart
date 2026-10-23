import 'game_level.dart';
import 'move_validator.dart';
import 'vehicle.dart';

/// Remove-only puzzle solver. A bit mask memo keeps the phase-one boards fast.
abstract final class LevelSolver {
  static bool isSolvable(GameLevel level) {
    if (level.vehicles.length > 62) {
      throw ArgumentError('The phase-one solver supports at most 62 vehicles.');
    }
    final failed = <int>{};
    final fullMask = (1 << level.vehicles.length) - 1;

    bool visit(int mask) {
      if (mask == 0) return true;
      if (!failed.add(mask)) return false;
      final remaining = <Vehicle>[];
      for (var index = 0; index < level.vehicles.length; index++) {
        if ((mask & (1 << index)) != 0) remaining.add(level.vehicles[index]);
      }
      for (final vehicle in MoveValidator.safeVehicles(level, remaining)) {
        final index = level.vehicles.indexOf(vehicle);
        if (visit(mask & ~(1 << index))) return true;
      }
      return false;
    }

    return visit(fullMask);
  }

  static List<String>? solve(GameLevel level) {
    if (level.vehicles.length > 62) return null;
    final failed = <int>{};
    final fullMask = (1 << level.vehicles.length) - 1;

    List<String>? visit(int mask) {
      if (mask == 0) return const [];
      if (!failed.add(mask)) return null;
      final remaining = <Vehicle>[];
      for (var index = 0; index < level.vehicles.length; index++) {
        if ((mask & (1 << index)) != 0) remaining.add(level.vehicles[index]);
      }
      for (final vehicle in MoveValidator.safeVehicles(level, remaining)) {
        final index = level.vehicles.indexOf(vehicle);
        final suffix = visit(mask & ~(1 << index));
        if (suffix != null) return [vehicle.id, ...suffix];
      }
      return null;
    }

    return visit(fullMask);
  }
}
