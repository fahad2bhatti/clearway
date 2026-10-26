import 'dart:isolate';

import '../../core/daily_clock.dart';
import '../engine/game_level.dart';
import '../generator/maze_level_generator.dart';

/// Deterministic yard catalog. Every board is a dense "arrow maze" made by
/// [MazeLevelGenerator] (curvy buses, only other buses in the way) and checked
/// by the same pure-Dart solver used in play.
abstract final class LevelCatalog {
  static const totalLevels = 80;
  static final Map<int, GameLevel> _levelCache = {};
  static final Map<int, Future<void>> _prefetching = {};
  static final Map<int, GameLevel> _dailyCache = {};

  /// Optional hook used by the Flutter app to report slow generation in debug.
  static void Function(int levelNumber, Duration elapsed)? onSlowGeneration;
  static const chapters = [
    'Lahore',
    'Karachi',
    'Multan',
    'Quetta',
    'Peshawar',
    'Faisalabad',
  ];

  static const levelsPerChapter = 10;

  static int get totalChapters =>
      (totalLevels + levelsPerChapter - 1) ~/ levelsPerChapter;

  /// 1-based chapter that [number] belongs to.
  static int chapterNumberFor(int number) =>
      (number - 1) ~/ levelsPerChapter + 1;

  static int firstLevelOfChapter(int chapterNumber) =>
      (chapterNumber - 1) * levelsPerChapter + 1;

  static int lastLevelOfChapter(int chapterNumber) {
    final end = chapterNumber * levelsPerChapter;
    return end < totalLevels ? end : totalLevels;
  }

  static bool startsChapter(int number) => (number - 1) % levelsPerChapter == 0;

  static String chapterFor(int number) =>
      chapters[(chapterNumberFor(number) - 1) % chapters.length];

  static GameLevel getLevel(int number) {
    if (number < 1 || number > totalLevels) {
      throw RangeError.range(number, 1, totalLevels, 'number');
    }
    final cached = _levelCache[number];
    if (cached != null) return cached;

    final timer = Stopwatch()..start();
    final level = MazeLevelGenerator.generate(
      number,
      chapter: chapterFor(number),
    );
    timer.stop();
    _levelCache[number] = level;
    if (timer.elapsed > const Duration(milliseconds: 50)) {
      onSlowGeneration?.call(number, timer.elapsed);
    }
    return level;
  }

  /// Generates level [number] on a background isolate and caches it, so the
  /// next [getLevel] call is instant and the UI thread never stalls.
  /// Safe to call repeatedly; it never throws (on failure [getLevel] simply
  /// generates the level on demand).
  static Future<void> prefetch(int number) {
    if (number < 1 || number > totalLevels || _levelCache.containsKey(number)) {
      return Future<void>.value();
    }
    return _prefetching[number] ??= _prefetch(number);
  }

  static Future<void> _prefetch(int number) async {
    final chapter = chapterFor(number);
    try {
      final level = await Isolate.run(
        () => MazeLevelGenerator.generate(number, chapter: chapter),
      );
      _levelCache.putIfAbsent(number, () => level);
    } catch (_) {
      // getLevel() regenerates on demand.
    } finally {
      _prefetching.remove(number);
    }
  }

  /// The Rush Hour board for [dayKey]: 100 buses, the same for everyone.
  static GameLevel daily(String dayKey, {int? serverSeed}) {
    final seed = serverSeed ?? DailyClock.seedFor(dayKey);
    final cached = _dailyCache[seed];
    if (cached != null) return cached;
    return _cacheDaily(seed, MazeLevelGenerator.generateDaily(seed));
  }

  /// Background version of [daily]; same rules as [prefetch].
  static Future<void> prefetchDaily(String dayKey, {int? serverSeed}) async {
    final seed = serverSeed ?? DailyClock.seedFor(dayKey);
    if (_dailyCache.containsKey(seed)) return;
    try {
      final level = await Isolate.run(
        () => MazeLevelGenerator.generateDaily(seed),
      );
      _cacheDaily(seed, level);
    } catch (_) {
      // daily() regenerates on demand.
    }
  }

  // Only today's board matters, so keep a single entry.
  static GameLevel _cacheDaily(int seed, GameLevel level) {
    _dailyCache
      ..clear()
      ..[seed] = level;
    return level;
  }
}
