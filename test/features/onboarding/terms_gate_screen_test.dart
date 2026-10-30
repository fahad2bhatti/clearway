import 'package:clearway/data/local_save.dart';
import 'package:clearway/features/onboarding/terms_gate_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('continue stays disabled until the box is ticked', (
    tester,
  ) async {
    final save = LocalSave();
    await tester.pumpWidget(MaterialApp(home: TermsGateScreen(save: save)));

    FilledButton button() =>
        tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button().onPressed, isNull);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    expect(button().onPressed, isNotNull);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(save.termsAccepted, isTrue);
    save.dispose();
  });
}
