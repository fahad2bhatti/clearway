import 'package:clearway/game/data/level_catalog.dart';
import 'package:clearway/game/engine/game_level.dart';
import 'package:clearway/game/engine/level_solver.dart';
import 'package:clearway/game/generator/maze_level_generator.dart';
import 'package:flutter_test/flutter_test.dart';

String _fingerprint(GameLevel level) => level.vehicles
    .map((v) => '${v.id}:${v.direction.name}:${v.cells.join()}')
    .join(';');

int _emptyCells(GameLevel level) {
  final covered = {for (final v in level.vehicles) ...v.cells};
  return level.shape!.where((c) => !covered.contains(c)).length;
}

void main() {
  group('daily board for any seed', () {
    // Edge values, then a spread of pseudo-random 32-bit server seeds.
    final seeds = <int>[
      0,
      1,
      2,
      0x7FFFFFFF,
      0x80000000,
      0xFFFFFFFF,
      20261024,
      for (var i = 1; i <= 12; i++) (i * 2654435761) & 0xFFFFFFFF,
    ];

    test('is complete, solvable and deterministic', () {
      for (final seed in seeds) {
        final board = LevelCatalog.daily('any', serverSeed: seed);
        expect(
          board.vehicles.length,
          greaterThanOrEqualTo(MazeLevelGenerator.dailyBuses),
          reason: 'seed=$seed',
        );
        expect(_emptyCells(board), 0, reason: 'seed=$seed');
        expect(LevelSolver.isSolvable(board), isTrue, reason: 'seed=$seed');
        expect(
          _fingerprint(LevelCatalog.daily('any', serverSeed: seed)),
          _fingerprint(board),
          reason: 'seed=$seed',
        );
      }
    });

    test(
      'out-of-range seeds from a damaged save still give a playable board',
      () {
        for (final seed in [-1, -5000000000, 0x100000000, 0x7FFFFFFFFFFFFFFF]) {
          final board = LevelCatalog.daily('any', serverSeed: seed);
          expect(
            board.vehicles.length,
            greaterThanOrEqualTo(MazeLevelGenerator.dailyBuses),
            reason: 'seed=$seed',
          );
          expect(_emptyCells(board), 0, reason: 'seed=$seed');
          expect(LevelSolver.isSolvable(board), isTrue, reason: 'seed=$seed');
        }
      },
    );
  });

  test('no level or daily board takes pathologically long to generate', () {
    // Generous ceiling: only catches a runaway generator, not machine speed.
    const ceilingMs = 3000;
    for (var n = 1; n <= LevelCatalog.totalLevels; n++) {
      final timer = Stopwatch()..start();
      MazeLevelGenerator.generate(n);
      expect(
        timer.elapsedMilliseconds,
        lessThan(ceilingMs),
        reason: 'level $n',
      );
    }
    for (final seed in [3, 999, 0xFFFFFFFF, 2103100923]) {
      final timer = Stopwatch()..start();
      LevelCatalog.daily('any', serverSeed: seed);
      expect(
        timer.elapsedMilliseconds,
        lessThan(ceilingMs),
        reason: 'daily seed $seed',
      );
    }
  });
}
