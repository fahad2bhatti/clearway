import '../../core/daily_clock.dart';

enum GameplayEventType { levelCleared, dailyCleared }

final class GameplayEvent {
  const GameplayEvent({
    required this.type,
    required this.level,
    required this.usedHint,
    required this.isBoss,
    required this.streak,
  });

  final GameplayEventType type;
  final int level;
  final bool usedHint;
  final bool isBoss;
  final int streak;

  bool get isDaily => type == GameplayEventType.dailyCleared;
}

enum AchievementObjective { clearWithoutHints, clearBoss, dailyStreak, reachLevel }

final class AchievementDefinition {
  const AchievementDefinition({
    required this.id,
    required this.objective,
    required this.target,
  });

  final String id;
  final AchievementObjective objective;
  final int target;
}

abstract final class AchievementCatalog {
  static const definitions = [
    AchievementDefinition(
      id: 'clear-10-no-hints',
      objective: AchievementObjective.clearWithoutHints,
      target: 10,
    ),
    AchievementDefinition(
      id: 'clear-boss',
      objective: AchievementObjective.clearBoss,
      target: 1,
    ),
    AchievementDefinition(
      id: 'daily-streak-7',
      objective: AchievementObjective.dailyStreak,
      target: 7,
    ),
    AchievementDefinition(
      id: 'reach-level-80',
      objective: AchievementObjective.reachLevel,
      target: 80,
    ),
  ];

  static AchievementDefinition? byId(String id) {
    for (final definition in definitions) {
      if (definition.id == id) return definition;
    }
    return null;
  }
}

enum DailyMissionObjective { clearLevels, clearWithoutHints, clearBoss }

final class DailyMissionDefinition {
  const DailyMissionDefinition({
    required this.id,
    required this.objective,
    required this.target,
    required this.coins,
  });

  final String id;
  final DailyMissionObjective objective;
  final int target;
  final int coins;
}

final class DailyMissionState {
  const DailyMissionState({
    required this.dayKey,
    required this.missions,
    this.progress = const {},
    this.claimed = const {},
  });

  final String dayKey;
  final List<DailyMissionDefinition> missions;
  final Map<String, int> progress;
  final Set<String> claimed;

  DailyMissionState copyWith({
    Map<String, int>? progress,
    Set<String>? claimed,
  }) => DailyMissionState(
    dayKey: dayKey,
    missions: missions,
    progress: progress ?? this.progress,
    claimed: claimed ?? this.claimed,
  );
}

abstract final class DailyMissionCatalog {
  static List<DailyMissionDefinition> forDay(String dayKey) {
    final seed = _hash(dayKey);
    final noHintTarget = 1 + seed % 2;
    final levelTarget = 2 + (seed ~/ 7) % 2;
    return [
      DailyMissionDefinition(
        id: '$dayKey-clear-levels',
        objective: DailyMissionObjective.clearLevels,
        target: levelTarget,
        coins: 20,
      ),
      DailyMissionDefinition(
        id: '$dayKey-no-hints',
        objective: DailyMissionObjective.clearWithoutHints,
        target: noHintTarget,
        coins: 25,
      ),
      DailyMissionDefinition(
        id: '$dayKey-clear-levels-bonus',
        objective: DailyMissionObjective.clearLevels,
        target: 3,
        coins: 30,
      ),
    ];
  }

  static DailyMissionState today({DateTimeClock? clock}) {
    final dayKey = DailyClock.dayKey(clock: clock);
    return DailyMissionState(dayKey: dayKey, missions: forDay(dayKey));
  }

  static int _hash(String value) {
    var hash = 17;
    for (final codeUnit in value.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return hash;
  }
}

final class AchievementTracker {
  static Map<String, int> apply(
    Map<String, int> current,
    GameplayEvent event,
  ) {
    final next = Map<String, int>.of(current);
    for (final definition in AchievementCatalog.definitions) {
      var increment = 0;
      switch (definition.objective) {
        case AchievementObjective.clearWithoutHints:
          increment = !event.isDaily && !event.usedHint ? 1 : 0;
        case AchievementObjective.clearBoss:
          increment = !event.isDaily && event.isBoss ? 1 : 0;
        case AchievementObjective.dailyStreak:
          increment = event.isDaily ? event.streak : 0;
        case AchievementObjective.reachLevel:
          increment = event.isDaily ? 0 : event.level;
      }
      if (increment == 0) continue;
      final old = next[definition.id] ?? 0;
      next[definition.id] = definition.objective ==
              AchievementObjective.reachLevel ||
          definition.objective == AchievementObjective.dailyStreak
          ? (old > increment ? old : increment).clamp(0, definition.target)
          : (old + increment).clamp(0, definition.target);
    }
    return next;
  }
}
