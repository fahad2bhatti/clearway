import 'package:clearway/game/level_clear_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host({
    Future<bool> Function()? onAd,
    VoidCallback? onNext,
    VoidCallback? onReplay,
    VoidCallback? onHome,
    bool reduceMotion = false,
  }) {
    final dialog = LevelClearDialog(
      title: 'Level cleared!',
      stars: 2,
      coinsEarned: 25,
      coinsLabel: (coins) => '+$coins coins',
      starsLabel: '2 of 3 stars',
      nextLabel: 'Next level',
      onNext: onNext ?? () {},
      replayLabel: 'Replay',
      onReplay: onReplay ?? () {},
      homeLabel: 'Home',
      onHome: onHome ?? () {},
      adLabel: onAd == null ? null : 'Watch ad · double reward',
      adDoneLabel: 'Reward doubled!',
      adFailedMessage: 'Ad not available',
      onAd: onAd,
    );
    return MaterialApp(
      home: reduceMotion
          ? MediaQuery(
              data: const MediaQueryData(
                size: Size(400, 900),
                disableAnimations: true,
              ),
              child: dialog,
            )
          : dialog,
    );
  }

  void useTallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('counts coins up and fires the three actions', (tester) async {
    useTallScreen(tester);
    var next = 0;
    var replay = 0;
    var home = 0;
    await tester.pumpWidget(
      host(
        onNext: () => next++,
        onReplay: () => replay++,
        onHome: () => home++,
      ),
    );
    expect(find.text('+0 coins'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Level cleared!'), findsOneWidget);
    expect(find.text('+25 coins'), findsOneWidget);

    await tester.tap(find.text('NEXT LEVEL'));
    await tester.tap(find.text('REPLAY'));
    await tester.tap(find.text('Home'));
    expect(next, 1);
    expect(replay, 1);
    expect(home, 1);
  });

  testWidgets('ad button doubles the coin counter once', (tester) async {
    useTallScreen(tester);
    var ads = 0;
    await tester.pumpWidget(
      host(
        onAd: () async {
          ads++;
          return true;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Watch ad · double reward'));
    await tester.pumpAndSettle();
    expect(find.text('Reward doubled!'), findsOneWidget);
    expect(find.text('+50 coins'), findsOneWidget);

    await tester.tap(find.text('Reward doubled!'));
    await tester.pumpAndSettle();
    expect(ads, 1);
  });

  testWidgets('failed ad shows a message and allows a retry', (tester) async {
    useTallScreen(tester);
    var ads = 0;
    await tester.pumpWidget(
      host(
        onAd: () async {
          ads++;
          return false;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Watch ad · double reward'));
    await tester.pumpAndSettle();
    expect(find.text('Ad not available'), findsOneWidget);
    expect(find.text('+25 coins'), findsOneWidget);

    await tester.tap(find.text('Watch ad · double reward'));
    await tester.pumpAndSettle();
    expect(ads, 2);
  });

  testWidgets('no ad button without an ad label', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(find.textContaining('Watch ad'), findsNothing);
  });

  testWidgets('reduced motion shows the final state immediately', (
    tester,
  ) async {
    useTallScreen(tester);
    await tester.pumpWidget(host(reduceMotion: true));
    await tester.pump();
    expect(find.text('+25 coins'), findsOneWidget);
  });
}
