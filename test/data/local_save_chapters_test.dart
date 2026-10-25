import 'dart:convert';

import 'package:clearway/data/local_save.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<LocalSave> _loadWith(Map<String, Object?> data) async {
  SharedPreferences.setMockInitialValues({
    'clearway-save-v1': jsonEncode(data),
  });
  final save = LocalSave();
  await save.load();
  return save;
}

Future<LocalSave> _reload() async {
  final save = LocalSave();
  await save.load();
  return save;
}

String _seen(LocalSave save) => (save.chaptersSeen.toList()..sort()).join(',');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('chapter cards already shown', () {
    test('a brand new game has shown no chapter card', () async {
      final save = LocalSave();
      await save.load();
      expect(_seen(save), '');
      save.dispose();
    });

    test('shown chapters are saved and come back after a restart', () async {
      final save = LocalSave()..chaptersSeen.addAll({2, 3});
      await save.save();
      final restored = await _reload();
      expect(_seen(restored), '2,3');
      save.dispose();
      restored.dispose();
    });

    test('an old save counts the chapters it already moved past', () async {
      final fresh = await _loadWith({'level': 1});
      expect(_seen(fresh), '');
      fresh.dispose();

      final atFirstOfChapterTwo = await _loadWith({'level': 11});
      expect(_seen(atFirstOfChapterTwo), '1');
      atFirstOfChapterTwo.dispose();

      final insideChapterTwo = await _loadWith({'level': 12});
      expect(_seen(insideChapterTwo), '1,2');
      insideChapterTwo.dispose();

      final laterOn = await _loadWith({'level': 25});
      expect(_seen(laterOn), '1,2,3');
      laterOn.dispose();
    });

    test('a stored list is kept and topped up from the level', () async {
      final save = await _loadWith({
        'level': 25,
        'chaptersSeen': [3],
      });
      expect(_seen(save), '1,2,3');
      save.dispose();
    });

    test('damaged entries are ignored and never break loading', () async {
      final save = await _loadWith({
        'level': 1,
        'chaptersSeen': [2, 'x', 99, -1, 0, 3.5, null, 8],
      });
      expect(save.level, 1);
      expect(_seen(save), '2,8');
      save.dispose();
    });

    test('a value that is not a list is treated as missing', () async {
      for (final bad in [
        '2',
        2,
        true,
        {'a': 1},
      ]) {
        final save = await _loadWith({'level': 12, 'chaptersSeen': bad});
        expect(_seen(save), '1,2', reason: 'value=$bad');
        save.dispose();
      }
    });

    test('resetting the game forgets the shown chapters', () async {
      final save = LocalSave()..chaptersSeen.addAll({2, 3});
      await save.save();
      await save.reset();
      expect(_seen(save), '');
      final restored = await _reload();
      expect(_seen(restored), '');
      save.dispose();
      restored.dispose();
    });

    test('cloud progress marks the chapters it moves past', () async {
      final save = LocalSave();
      await save.mergeCloudProgress(25, const {});
      expect(_seen(save), '1,2,3');
      final restored = await _reload();
      expect(_seen(restored), '1,2,3');
      save.dispose();
      restored.dispose();
    });
  });
}
