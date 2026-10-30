import 'package:clearway/data/local_save.dart';
import 'package:clearway/services/economy_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('undo pack costs 30 coins, adds 3 undos and survives reload', () async {
    final save = LocalSave()..coins = 100;
    final undosBefore = save.undos;

    final result = await EconomyRepository(save).buyOffer('undo-pack');

    expect(result.success, isTrue);
    expect(save.coins, 70);
    expect(save.undos, undosBefore + 3);

    final restored = LocalSave();
    await restored.load();
    expect(restored.coins, 70);
    expect(restored.undos, undosBefore + 3);
    save.dispose();
    restored.dispose();
  });

  test('undo pack is refused without enough coins', () async {
    final save = LocalSave()..coins = 29;
    final undosBefore = save.undos;

    final result = await EconomyRepository(save).buyOffer('undo-pack');

    expect(result.success, isFalse);
    expect(result.reason, 'insufficient');
    expect(save.coins, 29);
    expect(save.undos, undosBefore);
    save.dispose();
  });
}
