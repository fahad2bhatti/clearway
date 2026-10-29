import 'package:clearway/data/local_save.dart';
import 'package:clearway/game/milestones/milestone_config.dart';
import 'package:clearway/game/skins/arrow_skin.dart';
import 'package:clearway/services/economy_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('classic skin uses one monochrome color', () {
    expect(ArrowSkinCatalog.classic.primaryColors, hasLength(1));
  });

  test('skin purchase is atomic and duplicate-safe', () async {
    final save = LocalSave()..coins = ArrowSkinCatalog.sunset.price;
    final economy = EconomyRepository(save);

    expect((await economy.buySkin(ArrowSkinCatalog.sunset)).success, isTrue);
    expect(save.coins, 0);
    expect((await economy.buySkin(ArrowSkinCatalog.sunset)).success, isFalse);
    expect(save.coins, 0);
    save.dispose();
  });

  test('milestones and level 80 skin are idempotent', () async {
    final save = LocalSave()..level = 80;
    final economy = EconomyRepository(save);

    final first = await economy.grantMilestonesThrough(80);
    final second = await economy.grantMilestonesThrough(80);

    expect(first.coins, greaterThan(0));
    expect(first.hints, greaterThan(0));
    expect(first.skinUnlocked, isTrue);
    expect(second.isEmpty, isTrue);
    expect(save.claimedMilestones, hasLength(MilestoneConfig.rewards.length));
    expect(save.ownedArrowSkins, contains(ArrowSkinCatalog.spectrum.id));
    save.dispose();
  });
}
