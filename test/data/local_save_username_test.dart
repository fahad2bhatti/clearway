import 'package:clearway/data/local_save.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('invalid usernames are refused and nothing is saved', () async {
    final save = LocalSave();

    expect(await save.completeOnboarding('a b'), isFalse);
    expect(await save.completeOnboarding('ab'), isFalse);

    expect(save.termsAccepted, isFalse);
    expect(save.username, '');
    save.dispose();
  });

  test('a valid username and the terms acceptance survive reload', () async {
    final save = LocalSave();
    expect(await save.completeOnboarding('Fahad_1'), isTrue);

    final restored = LocalSave();
    await restored.load();

    expect(restored.username, 'Fahad_1');
    expect(restored.termsAccepted, isTrue);
    expect(restored.onboardingComplete, isTrue);
    save.dispose();
    restored.dispose();
  });

  test('players who only accepted the terms still need a username', () async {
    final save = LocalSave();
    await save.acceptTerms();

    expect(save.termsAccepted, isTrue);
    expect(save.onboardingComplete, isFalse);
    save.dispose();
  });

  test('reset clears the username', () async {
    final save = LocalSave();
    await save.completeOnboarding('Fahad_1');

    await save.reset();

    expect(save.username, '');
    expect(save.onboardingComplete, isFalse);
    save.dispose();
  });
}
