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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('tutorial completion', () {
    test('a brand new game has not finished the tutorial', () async {
      final save = LocalSave();
      expect(save.tutorialDone, isFalse);
      await save.load();
      expect(save.tutorialDone, isFalse);
      save.dispose();
    });

    test('the flag is saved and comes back after a restart', () async {
      final save = LocalSave()..tutorialDone = true;
      await save.save();

      final restored = await _reload();
      expect(restored.tutorialDone, isTrue);
      save.dispose();
      restored.dispose();
    });

    test('an old save with no flag is judged by its unlocked level', () async {
      final fresh = await _loadWith({'level': 1});
      expect(fresh.tutorialDone, isFalse);
      fresh.dispose();

      final almost = await _loadWith({'level': 3});
      expect(almost.tutorialDone, isFalse);
      almost.dispose();

      final past = await _loadWith({'level': 4});
      expect(past.tutorialDone, isTrue);
      past.dispose();
    });

    test('a stored true is kept even on level 1', () async {
      final save = await _loadWith({'level': 1, 'tutorialDone': true});
      expect(save.tutorialDone, isTrue);
      save.dispose();
    });

    test('a damaged flag value never breaks loading', () async {
      for (final bad in ['yes', 1, null, <String>[], 'true']) {
        final save = await _loadWith({'level': 2, 'tutorialDone': bad});
        expect(save.level, 2, reason: 'flag=$bad');
        expect(save.tutorialDone, isFalse, reason: 'flag=$bad');
        save.dispose();
      }
    });

    test('a false flag cannot hide that later levels are unlocked', () async {
      final save = await _loadWith({'level': 9, 'tutorialDone': false});
      expect(save.tutorialDone, isTrue);
      save.dispose();
    });

    test('resetting the game starts the tutorial again', () async {
      final save = LocalSave()..tutorialDone = true;
      await save.save();
      await save.reset();
      expect(save.tutorialDone, isFalse);

      final restored = await _reload();
      expect(restored.tutorialDone, isFalse);
      save.dispose();
      restored.dispose();
    });

    test(
      'cloud progress past the guided levels finishes the tutorial',
      () async {
        final save = LocalSave();
        await save.mergeCloudProgress(5, const {});
        expect(save.tutorialDone, isTrue);

        final restored = await _reload();
        expect(restored.tutorialDone, isTrue);
        save.dispose();
        restored.dispose();
      },
    );

    test(
      'cloud progress inside the guided levels leaves it unfinished',
      () async {
        final save = LocalSave();
        await save.mergeCloudProgress(2, const {1: 3});
        expect(save.tutorialDone, isFalse);
        save.dispose();
      },
    );
  });
}
