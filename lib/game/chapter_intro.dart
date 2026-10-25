import 'data/level_catalog.dart';

/// Rules for the card shown when a new chapter begins.
abstract final class ChapterIntro {
  /// Chapter 1 is introduced by the home screen and the tutorial, so cards
  /// start at chapter 2.
  static const firstCardChapter = 2;

  /// The chapter whose card should open when [levelNumber] loads, or null when
  /// no card is due. [seen] holds the chapters already shown.
  static int? due(int levelNumber, Set<int> seen) {
    if (!LevelCatalog.startsChapter(levelNumber)) return null;
    final chapter = LevelCatalog.chapterNumberFor(levelNumber);
    if (chapter < firstCardChapter || seen.contains(chapter)) return null;
    return chapter;
  }
}
