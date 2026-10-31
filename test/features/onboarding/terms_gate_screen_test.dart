import 'package:clearway/core/clearway_strings.dart';
import 'package:clearway/data/local_save.dart';
import 'package:clearway/features/onboarding/terms_gate_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  final strings = ClearwayStrings('en');

  FilledButton continueButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton));

  testWidgets('continue needs the box ticked and a valid username', (
    tester,
  ) async {
    final save = LocalSave();
    await tester.pumpWidget(MaterialApp(home: TermsGateScreen(save: save)));
    expect(continueButton(tester).onPressed, isNull);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    expect(continueButton(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'ab');
    await tester.pump();
    expect(find.text(strings.usernameTooShort), findsOneWidget);
    expect(continueButton(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Fahad_1');
    await tester.pump();
    expect(continueButton(tester).onPressed, isNotNull);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(save.termsAccepted, isTrue);
    expect(save.username, 'Fahad_1');
    save.dispose();
  });

  testWidgets('spaces and symbols show the invalid-character message', (
    tester,
  ) async {
    final save = LocalSave();
    await tester.pumpWidget(MaterialApp(home: TermsGateScreen(save: save)));

    await tester.tap(find.byType(CheckboxListTile));
    await tester.enterText(find.byType(TextField), 'a b!');
    await tester.pump();

    expect(find.text(strings.usernameInvalid), findsOneWidget);
    expect(continueButton(tester).onPressed, isNull);
    save.dispose();
  });

  testWidgets('players who already accepted the terms only need a username', (
    tester,
  ) async {
    final save = LocalSave();
    await tester.runAsync(save.acceptTerms);
    await tester.pumpWidget(MaterialApp(home: TermsGateScreen(save: save)));

    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isTrue,
    );
    expect(continueButton(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Fahad_1');
    await tester.pump();
    expect(continueButton(tester).onPressed, isNotNull);
    save.dispose();
  });
}
