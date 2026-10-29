import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/daily_clock.dart';
import '../game/data/level_catalog.dart';
import '../game/tutorial.dart';
import '../game/skins/arrow_skin.dart';
import '../game/milestones/milestone_config.dart';
import '../game/achievements/achievement_models.dart';

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

  // Ad rewards (sirf local, cloud mein nahi jate).
  static const dailyGiftCoins = 50;
  static const adCoinsReward = 30;
  static const maxAdCoinsPerDay = 5;

  /// Shop: a hint pack is deliberately pricey (25 coins per hint).
  static const hintPackCost = 50;
  static const hintPackSize = 2;
  String giftDay = '';
  String adCoinsDay = '';
  int adCoinsCount = 0;

  /// Aaj shop se kitni bar aur "ad dekho, coins pao" mil sakta hai.
  int get adCoinsLeft => adCoinsDay == DailyClock.dayKey()
      ? (maxAdCoinsPerDay - adCoinsCount).clamp(0, maxAdCoinsPerDay)
      : maxAdCoinsPerDay;

  void recordAdCoins() {
    final today = DailyClock.dayKey();
    if (adCoinsDay != today) {
      adCoinsDay = today;
      adCoinsCount = 0;
    }
    adCoinsCount++;
  }

  bool sound = true;
  bool music = false;
  bool haptics = true;
  bool darkTheme = true;
  bool colorblind = false;
  bool notifications = true;
  String language = 'en';
  bool tutorialDone = false;
  final Set<int> chaptersSeen = {};
  Map<String, dynamic>? activeBoard;
  final Map<int, int> stars = {};
  final Set<String> completedDailies = {};
  final Set<String> ownedArrowSkins = {'classic'};
  String selectedArrowSkin = 'classic';
  final Set<String> claimedMilestones = {};
  final Map<String, int> achievementProgress = {};
  final Set<String> claimedAchievements = {};
  DailyMissionState? dailyMissions;

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
    level = ((data['level'] as num?)?.toInt() ?? 1).clamp(
      1,
      LevelCatalog.totalLevels,
    );
    coins = _count(data['coins'], 30);
    hints = _count(data['hints'], 3);
    undos = _count(data['undos'], 3);
    streak = _count(data['streak'], 0);
    lastDaily = data['lastDaily'] as String? ?? '';
    giftDay = data['giftDay'] as String? ?? '';
    adCoinsDay = data['adCoinsDay'] as String? ?? '';
    adCoinsCount = _count(data['adCoinsCount'], 0);
    sound = data['sound'] as bool? ?? true;
    music = data['music'] as bool? ?? false;
    haptics = data['haptics'] as bool? ?? true;
    darkTheme = (data['theme'] as String? ?? 'dark') == 'dark';
    colorblind = data['colorblind'] as bool? ?? false;
    notifications = data['notifications'] as bool? ?? true;
    language = data['lang'] as String? ?? 'en';
    ownedArrowSkins
      ..clear()
      ..addAll(
        (data['arrowSkins'] as List<dynamic>? ?? ['classic'])
            .whereType<String>()
            .where(ArrowSkinCatalog.contains),
      );
    if (ownedArrowSkins.isEmpty) ownedArrowSkins.add('classic');
    if (level >= ArrowSkinCatalog.spectrum.unlockLevel!) {
      ownedArrowSkins.add(ArrowSkinCatalog.spectrum.id);
    }
    selectedArrowSkin = ownedArrowSkins.contains(data['selectedArrowSkin'])
        ? data['selectedArrowSkin'] as String
        : 'classic';
    claimedMilestones
      ..clear()
      ..addAll(
        (data['claimedMilestones'] as List<dynamic>? ?? [])
            .whereType<String>()
            .where(
              (id) => MilestoneConfig.rewards.any((reward) => reward.id == id),
            ),
      );
    achievementProgress
      ..clear()
      ..addAll(
        (data['achievementProgress'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(key, (value as num).toInt().clamp(0, 1000)),
        ),
      );
    claimedAchievements
      ..clear()
      ..addAll(
        (data['claimedAchievements'] as List<dynamic>? ?? [])
            .whereType<String>()
            .where((id) => AchievementCatalog.byId(id) != null),
      );
    dailyMissions = _decodeDailyMissions(data['dailyMissions']);
    // Saves from before this flag existed carry no value: anyone who has
    // already unlocked level 4 must have won the guided levels.
    tutorialDone = data['tutorialDone'] == true || Tutorial.finishedBy(level);
    chaptersSeen.clear();
    final seen = data['chaptersSeen'];
    if (seen is List) {
      for (final chapter in seen) {
        if (chapter is int &&
            chapter >= 1 &&
            chapter <= LevelCatalog.totalChapters) {
          chaptersSeen.add(chapter);
        }
      }
    }
    _markPlayedChapters();
    final board = data['activeBoard'] as Map<String, dynamic>?;
    activeBoard = board != null && _isPlayableBoard(board) ? board : null;
    stars.clear();
    for (final entry
        in (data['stars'] as Map<String, dynamic>? ?? {}).entries) {
      final number = int.parse(entry.key);
      final earned = (entry.value as num).toInt().clamp(0, 3);
      if (earned > 0 && number >= 1 && number <= LevelCatalog.totalLevels) {
        stars[number] = earned;
      }
    }
    completedDailies
      ..clear()
      ..addAll((data['dailies'] as List<dynamic>? ?? []).cast<String>());
  }

  static int _count(Object? value, int fallback) {
    final count = (value as num?)?.toInt() ?? fallback;
    return count < 0 ? 0 : count;
  }

  /// A saved board must point at a real level (or a well-formed daily), or
  /// restoring it would throw on every launch.
  static bool _isPlayableBoard(Map<String, dynamic> board) {
    if (board['daily'] == true) {
      final seed = board['dailySeed'];
      return board['dayKey'] is String && (seed == null || seed is num);
    }
    final number = board['level'];
    return number is num && number >= 1 && number <= LevelCatalog.totalLevels;
  }

  void _resetInMemory() {
    level = 1;
    coins = 30;
    hints = 3;
    undos = 3;
    streak = 0;
    lastDaily = '';
    giftDay = '';
    adCoinsDay = '';
    adCoinsCount = 0;
    sound = true;
    music = false;
    haptics = true;
    darkTheme = true;
    colorblind = false;
    notifications = true;
    language = 'en';
    tutorialDone = false;
    chaptersSeen.clear();
    activeBoard = null;
    stars.clear();
    completedDailies.clear();
    ownedArrowSkins
      ..clear()
      ..add('classic');
    selectedArrowSkin = 'classic';
    claimedMilestones.clear();
    achievementProgress.clear();
    claimedAchievements.clear();
    dailyMissions = null;
  }

  /// Chapters the player has already moved past never show their intro card:
  /// older saves and cloud progress carry no record of it.
  bool _markPlayedChapters() {
    var changed = false;
    for (var chapter = 1; chapter <= LevelCatalog.totalChapters; chapter++) {
      if (LevelCatalog.firstLevelOfChapter(chapter) < level &&
          chaptersSeen.add(chapter)) {
        changed = true;
      }
    }
    return changed;
  }

  Future<void> save({bool notify = true}) async {
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
        'notifications': notifications,
        'lang': language,
        'arrowSkins': ownedArrowSkins.toList()..sort(),
        'selectedArrowSkin': selectedArrowSkin,
        'claimedMilestones': claimedMilestones.toList()..sort(),
        'achievementProgress': achievementProgress,
        'claimedAchievements': claimedAchievements.toList()..sort(),
        'dailyMissions': _encodeDailyMissions(dailyMissions),
        'tutorialDone': tutorialDone,
        'chaptersSeen': (chaptersSeen.toList()..sort()),
        'streak': streak,
        'lastDaily': lastDaily,
        'giftDay': giftDay,
        'adCoinsDay': adCoinsDay,
        'adCoinsCount': adCoinsCount,
        'dailies': completedDailies.toList(),
        'activeBoard': activeBoard,
      }),
    );
    if (notify) notifyListeners();
  }

  Future<void> mergeCloudProgress(
    int highestLevel,
    Map<int, int> cloudStars,
    {
    Set<String> cloudArrowSkins = const {'classic'},
    String cloudSelectedArrowSkin = 'classic',
    Set<String> cloudClaimedMilestones = const {},
    Map<String, int> cloudAchievementProgress = const {},
    Set<String> cloudClaimedAchievements = const {},
    DailyMissionState? cloudDailyMissions,
    }
  ) async {
    final mergedLevel = highestLevel > level ? highestLevel : level;
    var changed = mergedLevel != level;
    level = mergedLevel.clamp(1, LevelCatalog.totalLevels);
    if (Tutorial.finishedBy(level) && !tutorialDone) {
      tutorialDone = true;
      changed = true;
    }
    if (_markPlayedChapters()) changed = true;
    for (final entry in cloudStars.entries) {
      if (entry.key < 1 || entry.key > LevelCatalog.totalLevels) continue;
      final bounded = entry.value.clamp(0, 3);
      final current = stars[entry.key] ?? 0;
      if (bounded > current) {
        stars[entry.key] = bounded;
        changed = true;
      }
    }
    for (final skinId in cloudArrowSkins) {
      if (ArrowSkinCatalog.contains(skinId) &&
          ownedArrowSkins.add(skinId)) {
        changed = true;
      }
    }
    if (ownedArrowSkins.contains(cloudSelectedArrowSkin) &&
        selectedArrowSkin != cloudSelectedArrowSkin) {
      selectedArrowSkin = cloudSelectedArrowSkin;
      changed = true;
    }
    for (final milestone in cloudClaimedMilestones) {
      if (milestone.startsWith('level-') &&
          MilestoneConfig.rewards.any((reward) => reward.id == milestone) &&
          claimedMilestones.add(milestone)) {
        changed = true;
      }
    }
    for (final entry in cloudAchievementProgress.entries) {
      final definition = AchievementCatalog.byId(entry.key);
      if (definition == null) continue;
      final value = entry.value.clamp(0, definition.target);
      if (value > (achievementProgress[entry.key] ?? 0)) {
        achievementProgress[entry.key] = value;
        changed = true;
      }
    }
    for (final achievement in cloudClaimedAchievements) {
      if (AchievementCatalog.byId(achievement) != null &&
          claimedAchievements.add(achievement)) {
        changed = true;
      }
    }
    if (cloudDailyMissions != null) {
      final localMissions = dailyMissions;
      if (localMissions == null ||
          cloudDailyMissions.dayKey.compareTo(localMissions.dayKey) > 0) {
        dailyMissions = cloudDailyMissions;
        changed = true;
      } else if (cloudDailyMissions.dayKey == localMissions.dayKey) {
        final mergedProgress = Map<String, int>.of(localMissions.progress);
        for (final mission in cloudDailyMissions.missions) {
          final remoteValue = cloudDailyMissions.progress[mission.id] ?? 0;
          final localValue = mergedProgress[mission.id] ?? 0;
          if (remoteValue > localValue) mergedProgress[mission.id] = remoteValue;
        }
        final mergedClaimed = {...localMissions.claimed, ...cloudDailyMissions.claimed};
        if (mergedProgress.length != localMissions.progress.length ||
            mergedClaimed.length != localMissions.claimed.length ||
            mergedProgress.entries.any(
              (entry) => entry.value != localMissions.progress[entry.key],
            )) {
          dailyMissions = localMissions.copyWith(
            progress: mergedProgress,
            claimed: mergedClaimed,
          );
          changed = true;
        }
      }
    }
    if (level >= ArrowSkinCatalog.spectrum.unlockLevel! &&
        ownedArrowSkins.add(ArrowSkinCatalog.spectrum.id)) {
      changed = true;
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
    giftDay = '';
    adCoinsDay = '';
    adCoinsCount = 0;
    stars.clear();
    completedDailies.clear();
    sound = true;
    music = false;
    haptics = true;
    darkTheme = true;
    colorblind = false;
    notifications = true;
    language = 'en';
    tutorialDone = false;
    chaptersSeen.clear();
    activeBoard = null;
    ownedArrowSkins
      ..clear()
      ..add('classic');
    selectedArrowSkin = 'classic';
    claimedMilestones.clear();
    achievementProgress.clear();
    claimedAchievements.clear();
    dailyMissions = null;
    notifyListeners();
  }

  void ensureDailyMissions() {
    final today = DailyMissionCatalog.today();
    if (dailyMissions?.dayKey != today.dayKey) {
      dailyMissions = today;
    }
  }

  void recordGameplayEvent(GameplayEvent event) {
    ensureDailyMissions();
    achievementProgress
      ..clear()
      ..addAll(AchievementTracker.apply(achievementProgress, event));
    final state = dailyMissions!;
    final progress = Map<String, int>.of(state.progress);
    for (final mission in state.missions) {
      final increment = switch (mission.objective) {
        DailyMissionObjective.clearLevels => event.isDaily ? 0 : 1,
        DailyMissionObjective.clearWithoutHints =>
          !event.isDaily && !event.usedHint ? 1 : 0,
        DailyMissionObjective.clearBoss =>
          !event.isDaily && event.isBoss ? 1 : 0,
      };
      if (increment > 0) {
        progress[mission.id] = (progress[mission.id] ?? 0) + increment;
      }
    }
    dailyMissions = state.copyWith(progress: progress);
  }

  DailyMissionState? _decodeDailyMissions(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final dayKey = raw['dayKey'];
    final definitions = raw['missions'];
    if (dayKey is! String || definitions is! List) return null;
    final missions = <DailyMissionDefinition>[];
    for (final item in definitions) {
      if (item is! Map<String, dynamic>) continue;
      final objective = switch (item['objective']) {
        'clearLevels' => DailyMissionObjective.clearLevels,
        'clearWithoutHints' => DailyMissionObjective.clearWithoutHints,
        'clearBoss' => DailyMissionObjective.clearBoss,
        _ => null,
      };
      if (objective == null ||
          item['id'] is! String ||
          item['target'] is! num ||
          item['coins'] is! num) {
        continue;
      }
      missions.add(
        DailyMissionDefinition(
          id: item['id'] as String,
          objective: objective,
          target: (item['target'] as num).toInt().clamp(1, 100),
          coins: (item['coins'] as num).toInt().clamp(1, 500),
        ),
      );
    }
    if (missions.length != 3) return null;
    final progress = <String, int>{};
    final rawProgress = raw['progress'];
    if (rawProgress is Map<String, dynamic>) {
      for (final mission in missions) {
        final value = (rawProgress[mission.id] as num?)?.toInt();
        if (value != null) progress[mission.id] = value.clamp(0, mission.target);
      }
    }
    final claimed = (raw['claimed'] as List<dynamic>? ?? [])
        .whereType<String>()
        .where((id) => missions.any((mission) => mission.id == id))
        .toSet();
    return DailyMissionState(
      dayKey: dayKey,
      missions: missions,
      progress: progress,
      claimed: claimed,
    );
  }

  Map<String, dynamic>? _encodeDailyMissions(DailyMissionState? state) {
    if (state == null) return null;
    return {
      'dayKey': state.dayKey,
      'missions': [
        for (final mission in state.missions)
          {
            'id': mission.id,
            'objective': mission.objective.name,
            'target': mission.target,
            'coins': mission.coins,
          },
      ],
      'progress': state.progress,
      'claimed': state.claimed.toList()..sort(),
    };
  }
}
