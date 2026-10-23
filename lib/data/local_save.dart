import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline-first progress matching the original browser game's local save.
final class LocalSave extends ChangeNotifier {
  static const _storageKey = 'clearway-save-v1';
  static const _backupKey = 'clearway-save-backup-v1';

  int level = 1;
  int coins = 30;
  int hints = 3;
  int undos = 3;
  int streak = 0;
  String lastDaily = '';
  bool sound = true;
  bool music = false;
  bool haptics = true;
  bool darkTheme = true;
  bool colorblind = false;
  String language = 'en';
  Map<String, dynamic>? activeBoard;
  final Map<int, int> stars = {};
  final Set<String> completedDailies = {};

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return;
      try {
        _apply(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        final backup = prefs.getString(_backupKey);
        if (backup == null) rethrow;
        _resetInMemory();
        _apply(jsonDecode(backup) as Map<String, dynamic>);
        await prefs.setString(_storageKey, backup);
      }
    } catch (_) {
      // A malformed primary and backup save should leave a fresh playable game.
      _resetInMemory();
    }
    notifyListeners();
  }

  void _apply(Map<String, dynamic> data) {
    level = (data['level'] as num?)?.toInt() ?? 1;
    coins = (data['coins'] as num?)?.toInt() ?? 30;
    hints = (data['hints'] as num?)?.toInt() ?? 3;
    undos = (data['undos'] as num?)?.toInt() ?? 3;
    streak = (data['streak'] as num?)?.toInt() ?? 0;
    lastDaily = data['lastDaily'] as String? ?? '';
    sound = data['sound'] as bool? ?? true;
    music = data['music'] as bool? ?? false;
    haptics = data['haptics'] as bool? ?? true;
    darkTheme = (data['theme'] as String? ?? 'dark') == 'dark';
    colorblind = data['colorblind'] as bool? ?? false;
    language = data['lang'] as String? ?? 'en';
    activeBoard = (data['activeBoard'] as Map<String, dynamic>?);
    stars
      ..clear()
      ..addAll(
        (data['stars'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(int.parse(key), (value as num).toInt()),
        ),
      );
    completedDailies
      ..clear()
      ..addAll((data['dailies'] as List<dynamic>? ?? []).cast<String>());
  }

  void _resetInMemory() {
    level = 1;
    coins = 30;
    hints = 3;
    undos = 3;
    streak = 0;
    lastDaily = '';
    sound = true;
    music = false;
    haptics = true;
    darkTheme = true;
    colorblind = false;
    language = 'en';
    activeBoard = null;
    stars.clear();
    completedDailies.clear();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getString(_storageKey);
    if (current != null) {
      try {
        if (jsonDecode(current) is Map<String, dynamic>) {
          await prefs.setString(_backupKey, current);
        }
      } catch (_) {
        // Never replace a known-good backup with corrupt current data.
      }
    }
    await prefs.setString(
      _storageKey,
      jsonEncode({
        'level': level,
        'stars': {
          for (final entry in stars.entries) '${entry.key}': entry.value,
        },
        'coins': coins,
        'hints': hints,
        'undos': undos,
        'sound': sound,
        'music': music,
        'haptics': haptics,
        'theme': darkTheme ? 'dark' : 'light',
        'colorblind': colorblind,
        'lang': language,
        'streak': streak,
        'lastDaily': lastDaily,
        'dailies': completedDailies.toList(),
        'activeBoard': activeBoard,
      }),
    );
    notifyListeners();
  }

  Future<void> mergeCloudProgress(
    int highestLevel,
    Map<int, int> cloudStars,
  ) async {
    final mergedLevel = highestLevel > level ? highestLevel : level;
    var changed = mergedLevel != level;
    level = mergedLevel.clamp(1, 80);
    for (final entry in cloudStars.entries) {
      if (entry.key < 1 || entry.key > 80) continue;
      final bounded = entry.value.clamp(0, 3);
      final current = stars[entry.key] ?? 0;
      if (bounded > current) {
        stars[entry.key] = bounded;
        changed = true;
      }
    }
    if (changed) await save();
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove(_backupKey);
    level = 1;
    coins = 30;
    hints = 3;
    undos = 3;
    streak = 0;
    lastDaily = '';
    stars.clear();
    completedDailies.clear();
    sound = true;
    music = false;
    haptics = true;
    darkTheme = true;
    colorblind = false;
    language = 'en';
    activeBoard = null;
    notifyListeners();
  }
}
