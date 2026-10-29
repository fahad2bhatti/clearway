import 'package:clearway/data/local_save.dart';
import 'package:clearway/game/achievements/achievement_models.dart';
import 'package:clearway/services/economy_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('persisting only the active board does not notify listeners', () async {
    final save = LocalSave();
    var notifications = 0;
    save.addListener(() => notifications++);

    save.activeBoard = {
      'level': 4,
      'remaining': ['truck-1'],
    };
    await save.save(notify: false);

    expect(notifications, 0);
    save.dispose();
  });

  test('level and star progress saves notify listeners', () async {
    final save = LocalSave();
    var notifications = 0;
    save.addListener(() => notifications++);

    save.level = 2;
    await save.save();
    expect(notifications, 1);

    save.stars[2] = 3;
    await save.save();
    expect(notifications, 2);
    save.dispose();
  });

  test('settings and arrow skin ownership survive reload', () async {
    final save = LocalSave()
      ..notifications = false
      ..selectedArrowSkin = 'sunset'
      ..ownedArrowSkins.add('sunset');
    await save.save();

    final restored = LocalSave();
    await restored.load();

    expect(restored.notifications, isFalse);
    expect(restored.ownedArrowSkins, contains('sunset'));
    expect(restored.selectedArrowSkin, 'sunset');
    save.dispose();
    restored.dispose();
  });

  test('gameplay events persist progress and claims are idempotent', () async {
    final save = LocalSave();
    for (var i = 0; i < 10; i++) {
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
    await save.save();

    final economy = EconomyRepository(save);
    expect(await economy.claimAchievement('clear-10-no-hints'), isTrue);
    expect(await economy.claimAchievement('clear-10-no-hints'), isFalse);
    final restored = LocalSave();
    await restored.load();
    expect(restored.claimedAchievements, contains('clear-10-no-hints'));
    save.dispose();
    restored.dispose();
  });
}
