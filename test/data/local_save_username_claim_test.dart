import 'package:clearway/data/local_save.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a username saved offline stays unclaimed until the server agrees', () async {
    final save = LocalSave();
    await save.completeOnboarding('Fahad_1');
    expect(save.usernameClaimed, isFalse);

    await save.markUsernameClaimed('Fahad_1');

    final restored = LocalSave();
    await restored.load();
    expect(restored.username, 'Fahad_1');
    expect(restored.usernameClaimed, isTrue);
    save.dispose();
    restored.dispose();
  });

  test('a claim result for an older name is ignored', () async {
    final save = LocalSave();
    await save.completeOnboarding('Fahad_1');

    await save.markUsernameClaimed('Other_1');
    await save.releaseUsername('Other_1');

    expect(save.username, 'Fahad_1');
    expect(save.usernameClaimed, isFalse);
    save.dispose();
  });

  test('a refused name sends the player back to pick another', () async {
    final save = LocalSave();
    await save.completeOnboarding('Fahad_1');

    await save.releaseUsername('Fahad_1');

    expect(save.username, '');
    expect(save.usernameTakenName, 'Fahad_1');
    expect(save.onboardingComplete, isFalse);
    expect(save.termsAccepted, isTrue);
    final restored = LocalSave();
    await restored.load();
    expect(restored.username, '');
    save.dispose();
    restored.dispose();
  });
}
