import 'package:clearway/game/achievements/achievement_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('achievement progress is driven by real clear events', () {
    var progress = <String, int>{};
    for (var i = 0; i < 10; i++) {
      progress = AchievementTracker.apply(
        progress,
        const GameplayEvent(
          type: GameplayEventType.levelCleared,
          level: 2,
          usedHint: false,
          isBoss: false,
          streak: 0,
        ),
      );
    }

    expect(progress['clear-10-no-hints'], 10);
    expect(progress['reach-level-80'], isNull);
  });

  test('boss and streak objectives use supported event facts', () {
    var progress = AchievementTracker.apply(
      const {},
      const GameplayEvent(
        type: GameplayEventType.levelCleared,
        level: 5,
        usedHint: false,
        isBoss: true,
        streak: 0,
      ),
    );
    progress = AchievementTracker.apply(
      progress,
      const GameplayEvent(
        type: GameplayEventType.dailyCleared,
        level: 1,
        usedHint: false,
        isBoss: false,
        streak: 7,
      ),
    );

    expect(progress['clear-boss'], 1);
    expect(progress['daily-streak-7'], 7);
  });

  test('daily missions are deterministic and always provide three objectives', () {
    final first = DailyMissionCatalog.forDay('2026-10-29');
    final second = DailyMissionCatalog.forDay('2026-10-29');

    expect(first.length, 3);
    expect(
      first.map((mission) => mission.id).toList(),
      second.map((mission) => mission.id).toList(),
    );
    expect(
      first.every((mission) => mission.objective != DailyMissionObjective.clearBoss),
      isTrue,
    );
  });
}
