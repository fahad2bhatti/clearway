import 'dart:convert';

import 'package:clearway/data/local_save.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a fresh install has not accepted the terms', () {
    final save = LocalSave();
    expect(save.termsAccepted, isFalse);
    save.dispose();
  });

  test('accepting the terms survives a reload', () async {
    final save = LocalSave();
    await save.acceptTerms();
    expect(save.termsAccepted, isTrue);
    save.dispose();

    final reloaded = LocalSave();
    await reloaded.load();
    expect(reloaded.termsAccepted, isTrue);
    reloaded.dispose();
  });

  test('an older accepted version must be accepted again', () async {
    SharedPreferences.setMockInitialValues({
      'clearway-save-v1': jsonEncode({'termsVersion': '1999-01-01'}),
    });
    final save = LocalSave();
    await save.load();
    expect(save.termsAccepted, isFalse);
    save.dispose();
  });

  test('reset clears the acceptance', () async {
    final save = LocalSave();
    await save.acceptTerms();
    await save.reset();
    expect(save.termsAccepted, isFalse);
    save.dispose();
  });
}
