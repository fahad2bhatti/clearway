import 'package:clearway/core/clearway_strings.dart';
import 'package:clearway/game/chapter_intro.dart';
import 'package:clearway/game/data/level_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('chapter numbering', () {
    test('ten levels per chapter and eight chapters in 80 levels', () {
      expect(LevelCatalog.levelsPerChapter, 10);
      expect(LevelCatalog.totalChapters, 8);
      expect(LevelCatalog.chapterNumberFor(1), 1);
      expect(LevelCatalog.chapterNumberFor(10), 1);
      expect(LevelCatalog.chapterNumberFor(11), 2);
      expect(LevelCatalog.chapterNumberFor(80), 8);
    });

    test('first and last level of every chapter line up', () {
      for (var chapter = 1; chapter <= LevelCatalog.totalChapters; chapter++) {
        final first = LevelCatalog.firstLevelOfChapter(chapter);
        final last = LevelCatalog.lastLevelOfChapter(chapter);
        expect(first, (chapter - 1) * 10 + 1);
        expect(last, chapter * 10);
        expect(LevelCatalog.chapterNumberFor(first), chapter);
        expect(LevelCatalog.chapterNumberFor(last), chapter);
        expect(LevelCatalog.startsChapter(first), isTrue);
        expect(LevelCatalog.startsChapter(first + 1), isFalse);
      }
    });

    test('chapter names keep following the old ten-level rule', () {
      for (var number = 1; number <= LevelCatalog.totalLevels; number++) {
        final expected = LevelCatalog
            .chapters[((number - 1) ~/ 10) % LevelCatalog.chapters.length];
        expect(
          LevelCatalog.chapterFor(number),
          expected,
          reason: 'level $number',
        );
      }
    });

    test('every chapter ends on a boss yard, as the card promises', () {
      for (var chapter = 1; chapter <= LevelCatalog.totalChapters; chapter++) {
        final last = LevelCatalog.lastLevelOfChapter(chapter);
        expect(LevelCatalog.getLevel(last).boss, isTrue, reason: 'level $last');
      }
    });
  });

  group('when a card is due', () {
    test('never for chapter 1', () {
      expect(ChapterIntro.due(1, <int>{}), isNull);
    });

    test('at the first level of chapter 2 and later, until seen', () {
      expect(ChapterIntro.due(11, <int>{}), 2);
      expect(ChapterIntro.due(21, <int>{1, 2}), 3);
      expect(ChapterIntro.due(71, <int>{}), 8);
      expect(ChapterIntro.due(11, <int>{2}), isNull);
    });

    test('never in the middle of a chapter', () {
      for (var number = 2; number <= 80; number++) {
        if (LevelCatalog.startsChapter(number)) continue;
        expect(
          ChapterIntro.due(number, <int>{}),
          isNull,
          reason: 'level $number',
        );
      }
    });
  });

  group('card text', () {
    const strings = ClearwayStrings('en');

    test('lines are built from the chapter facts', () {
      expect(strings.chapterLabel(2), 'CHAPTER 2');
      expect(strings.chapterLevels(11, 20), 'Levels 11–20');
      expect(strings.chapterBoard(9, 9), 'Boards start at 9×9.');
      expect(strings.chapterBoss(20), 'A boss yard waits at level 20.');
    });
  });
}
