import 'package:clearway/core/clearway_strings.dart';
import 'package:clearway/data/local_save.dart';
import 'package:clearway/features/shop/shop_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  const strings = ClearwayStrings('en');

  testWidgets('the shop lays out its offers and skins without errors', (
    tester,
  ) async {
    final save = LocalSave();
    await tester.pumpWidget(
      MaterialApp(
        home: ShopScreen(save: save, onBack: () {}),
      ),
    );

    expect(find.text(strings.shopTitle), findsOneWidget);
    expect(find.text(strings.shopOfferTitle('ad-coins')), findsOneWidget);
    expect(find.text(strings.shopOfferTitle('hint-pack')), findsOneWidget);
    expect(find.text(strings.shopOfferTitle('undo-pack')), findsOneWidget);
    expect(find.text(strings.shopSkins.toUpperCase()), findsOneWidget);
    expect(tester.takeException(), isNull);
    save.dispose();
  });
}
