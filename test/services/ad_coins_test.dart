import 'package:clearway/data/local_save.dart';
import 'package:clearway/services/economy_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('offline ad claim credits the fixed reward and uses one claim', () async {
    final save = LocalSave();
    final economy = EconomyRepository(save);
    final coinsBefore = save.coins;
    final leftBefore = save.adCoinsLeft;

    final result = await economy.claimAdCoins();

    expect(result.success, isTrue);
    expect(save.coins, coinsBefore + LocalSave.adCoinsReward);
    expect(save.adCoinsLeft, leftBefore - 1);
    save.dispose();
  });

  test('ad claim and remaining count survive reload', () async {
    final save = LocalSave();
    await EconomyRepository(save).claimAdCoins();

    final restored = LocalSave();
    await restored.load();

    expect(restored.coins, save.coins);
    expect(restored.adCoinsLeft, save.adCoinsLeft);
    save.dispose();
    restored.dispose();
  });

  test('claims stop at the daily limit without crediting extra coins', () async {
    final save = LocalSave();
    final economy = EconomyRepository(save);

    for (var i = 0; i < LocalSave.maxAdCoinsPerDay; i++) {
      expect((await economy.claimAdCoins()).success, isTrue);
    }
    final coinsAtLimit = save.coins;
    final extra = await economy.claimAdCoins();

    expect(extra.success, isFalse);
    expect(extra.reason, 'failed-precondition');
    expect(save.coins, coinsAtLimit);
    expect(save.adCoinsLeft, 0);
    save.dispose();
  });

  test('hint ad grants three hints and stops at the daily limit', () async {
    final save = LocalSave()..hints = 0;
    final economy = EconomyRepository(save);

    for (var i = 0; i < LocalSave.maxAdHintsPerDay; i++) {
      expect((await economy.claimAdHints()).success, isTrue);
    }

    expect(save.hints, LocalSave.adHintsReward * LocalSave.maxAdHintsPerDay);
    expect(save.adHintsLeft, 0);
    final extra = await economy.claimAdHints();
    expect(extra.success, isFalse);
    expect(extra.reason, 'failed-precondition');
    save.dispose();
  });
}
