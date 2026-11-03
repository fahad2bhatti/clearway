import 'package:clearway/data/local_save.dart';
import 'package:clearway/game/achievements/achievement_models.dart';
import 'package:clearway/services/economy_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  void clearLevels(LocalSave save, int count) {
    for (var i = 0; i < count; i++) {
      save.recordGameplayEvent(
        const GameplayEvent(
          type: GameplayEventType.levelCleared,
          level: 2,
          usedHint: false,
          isBoss: false,
          streak: 0,
        ),
      );
    }
  }

  test('claiming an achievement adds its coins once', () async {
    final save = LocalSave();
    clearLevels(save, 10);
    final economy = EconomyRepository(save);
    final before = save.coins;
    final reward = AchievementCatalog.byId('clear-10-no-hints')!.coins;

    expect(await economy.claimAchievement('clear-10-no-hints'), isTrue);
    expect(save.coins, before + reward);
    expect(await economy.claimAchievement('clear-10-no-hints'), isFalse);
    expect(save.coins, before + reward);
    save.dispose();
  });

  test(
    'claiming a fresh daily mission works and adds its coins once',
    () async {
      final save = LocalSave();
      save.ensureDailyMissions();
      clearLevels(save, 3);
      final economy = EconomyRepository(save);
      final mission = save.dailyMissions!.missions.first;
      final before = save.coins;

      expect(await economy.claimDailyMission(mission.id), isTrue);
      expect(save.coins, before + mission.coins);
      expect(save.dailyMissions!.claimed, contains(mission.id));
      expect(await economy.claimDailyMission(mission.id), isFalse);
      expect(save.coins, before + mission.coins);
      save.dispose();
    },
  );

  test('an unfinished mission or achievement cannot be claimed', () async {
    final save = LocalSave();
    save.ensureDailyMissions();
    final economy = EconomyRepository(save);
    final before = save.coins;

    expect(
      await economy.claimDailyMission(save.dailyMissions!.missions.first.id),
      isFalse,
    );
    expect(await economy.claimAchievement('clear-10-no-hints'), isFalse);
    expect(save.coins, before);
    save.dispose();
  });
}
