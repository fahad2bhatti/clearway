import 'package:clearway/data/local_save.dart';
import 'package:clearway/services/economy_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('signed-in-independent purchases and spending use local balances',
      () async {
    final save = LocalSave()
      ..coins = 100
      ..hints = 1
      ..undos = 1;
    final economy = EconomyRepository(save);

    expect((await economy.buyOffer('hint-pack')).success, isTrue);
    expect(save.coins, 50);
    expect(save.hints, 3);

    expect((await economy.spend('hint')).success, isTrue);
    expect(save.hints, 2);
    expect((await economy.spend('undo')).success, isTrue);
    expect(save.undos, 0);
    expect((await economy.spend('revive')).success, isTrue);
    expect(save.coins, 20);
    save.dispose();
  });

  test('local milestone claims grant rewards once', () async {
    final save = LocalSave();
    final economy = EconomyRepository(save);

    final first = await economy.grantMilestonesThrough(10);
    final second = await economy.grantMilestonesThrough(10);

    expect(first.isEmpty, isFalse);
    expect(second.isEmpty, isTrue);
    expect(save.claimedMilestones, isNotEmpty);
    save.dispose();
  });
}
