import '../../core/daily_clock.dart';
import '../engine/game_level.dart';
import '../generator/maze_level_generator.dart';

/// Deterministic yard catalog. Every board is a dense "arrow maze" made by
/// [MazeLevelGenerator] (curvy buses, only other buses in the way) and checked
/// by the same pure-Dart solver used in play.
abstract final class LevelCatalog {
  static const totalLevels = 80;
  static final Map<int, GameLevel> _levelCache = {};

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

  /// The Rush Hour board for [dayKey]: 100 buses, the same for everyone.
  static GameLevel daily(String dayKey, {int? serverSeed}) {
    final seed = serverSeed ?? DailyClock.seedFor(dayKey);
    return MazeLevelGenerator.generateDaily(seed);
  }
}
