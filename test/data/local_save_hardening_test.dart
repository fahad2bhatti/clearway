import 'dart:convert';

import 'package:clearway/data/local_save.dart';
import 'package:clearway/game/data/level_catalog.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('a tampered or corrupt save can never break the game', () {
    test('level is clamped into the catalog range', () async {
      for (final bad in [9999, 0, -3, 2000000000]) {
        final save = await _loadWith({'level': bad});
        expect(save.level, greaterThanOrEqualTo(1), reason: 'level=$bad');
        expect(
          save.level,
          lessThanOrEqualTo(LevelCatalog.totalLevels),
          reason: 'level=$bad',
        );
        save.dispose();
      }
    });

    test('coins, hints, undos and streak are never negative', () async {
      final save = await _loadWith({
        'coins': -500,
        'hints': -1,
        'undos': -7,
        'streak': -2,
      });
      expect(save.coins, greaterThanOrEqualTo(0));
      expect(save.hints, greaterThanOrEqualTo(0));
      expect(save.undos, greaterThanOrEqualTo(0));
      expect(save.streak, greaterThanOrEqualTo(0));
      save.dispose();
    });

    test('stars keep only real levels with 1 to 3 stars', () async {
      final save = await _loadWith({
        'stars': {'5': 99, '-4': 2, '99999': 3, '7': 2, '8': 0},
      });
      expect(save.stars[5], 3);
      expect(save.stars[7], 2);
      expect(save.stars.containsKey(-4), isFalse);
      expect(save.stars.containsKey(99999), isFalse);
      expect(save.stars.containsKey(8), isFalse);
      save.dispose();
    });

    test(
      'an active board for a level that does not exist is dropped',
      () async {
        for (final level in [0, -1, LevelCatalog.totalLevels + 1, 5000]) {
          final save = await _loadWith({
            'activeBoard': {'level': level, 'daily': false, 'remaining': []},
          });
          expect(save.activeBoard, isNull, reason: 'level=$level');
          save.dispose();
        }
      },
    );

    test('a daily active board keeps its large level number', () async {
      final save = await _loadWith({
        'activeBoard': {
          'level': 920261024,
          'daily': true,
          'dayKey': '2026-10-24',
          'remaining': ['bus-1'],
        },
      });
      expect(save.activeBoard, isNotNull);
      save.dispose();
    });

    test('a valid save is loaded unchanged', () async {
      final save = await _loadWith({
        'level': 12,
        'coins': 140,
        'hints': 2,
        'undos': 1,
        'streak': 4,
        'stars': {'1': 3, '2': 1},
        'activeBoard': {
          'level': 12,
          'daily': false,
          'remaining': ['bus-1'],
        },
      });
      expect(save.level, 12);
      expect(save.coins, 140);
      expect(save.hints, 2);
      expect(save.undos, 1);
      expect(save.streak, 4);
      expect(save.stars, {1: 3, 2: 1});
      expect(save.activeBoard, isNotNull);
      save.dispose();
    });
  });
}
