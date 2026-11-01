import 'package:flutter_test/flutter_test.dart';

import 'package:clearway/core/daily_clock.dart';
import 'package:clearway/game/data/level_catalog.dart';
import 'package:clearway/game/engine/game_level.dart';
import 'package:clearway/game/generator/maze_level_generator.dart';

String _fingerprint(GameLevel level) =>
    [for (final v in level.vehicles) '${v.id}:${v.direction.name}:${v.cells}']
        .join('|');

void main() {
  group('background level prefetch', () {
    test('prefetch builds the same level the sync path would', () async {
      await LevelCatalog.prefetch(7);
      final cached = LevelCatalog.getLevel(7);
      final direct = MazeLevelGenerator.generate(
        7,
        chapter: LevelCatalog.chapterFor(7),
      );
      expect(_fingerprint(cached), _fingerprint(direct));
      expect(identical(cached, LevelCatalog.getLevel(7)), isTrue);
    });

    test('prefetch ignores out-of-range levels', () async {
      await LevelCatalog.prefetch(0);
      await LevelCatalog.prefetch(LevelCatalog.totalLevels + 1);
    });

    test('prefetchDaily matches the sync daily board and is cached', () async {
      const day = '2026-10-24';
      await LevelCatalog.prefetchDaily(day);
      final cached = LevelCatalog.daily(day);
      expect(
        _fingerprint(cached),
        _fingerprint(
          MazeLevelGenerator.generateDaily(DailyClock.seedFor(day)),
        ),
      );
      expect(identical(cached, LevelCatalog.daily(day)), isTrue);
    });
  });
}
