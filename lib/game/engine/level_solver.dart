import 'game_level.dart';
import 'move_validator.dart';

/// How a level plays out when every free vehicle is removed round by round.
final class SolveReport {
  const SolveReport({
    required this.taps,
    required this.rounds,
    required this.initiallyFree,
  });

  /// Tapped vehicle ids in a valid order. A convoy pair counts as one tap.
  final List<String> taps;

  /// Dependency depth: how many "waves" of removals the board needs.
  final int rounds;

  /// Vehicles that can leave right at the start.
  final int initiallyFree;
}

/// Remove-only puzzle solver.
///
/// Removing a vehicle only ever frees cells, so it can never block another
/// vehicle. That means a level is solvable if and only if repeatedly removing
/// every currently free vehicle empties the board: no search is needed, and
/// boards with hundreds of vehicles are checked quickly.
abstract final class LevelSolver {
  static bool isSolvable(GameLevel level) => analyze(level) != null;

  /// Returns the tapped vehicle ids in order, or null if unsolvable.
  static List<String>? solve(GameLevel level) => analyze(level)?.taps;

  /// Full report, or null if some vehicles can never leave.
  static SolveReport? analyze(GameLevel level) {
    var remaining = level.vehicles.toList(growable: false);
    final taps = <String>[];
    var rounds = 0;
    int? initiallyFree;
    while (remaining.isNotEmpty) {
      final safe = MoveValidator.safeVehicles(level, remaining);
      if (safe.isEmpty) return null;
      initiallyFree ??= safe.length;
      rounds++;
      final removed = <String>{};
      final seenConvoys = <String>{};
      for (final vehicle in safe) {
        removed.add(vehicle.id);
        final convoyId = vehicle.convoyId;
        if (convoyId == null || seenConvoys.add(convoyId)) {
          taps.add(vehicle.id);
        }
      }
      remaining = [
        for (final vehicle in remaining)
          if (!removed.contains(vehicle.id)) vehicle,
      ];
    }
    return SolveReport(
      taps: List.unmodifiable(taps),
      rounds: rounds,
      initiallyFree: initiallyFree ?? 0,
    );
  }
}
