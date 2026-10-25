import 'package:clearway/game/revive.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a revive costs coins and gives back exactly one life', () {
    expect(Revive.cost, 30);
    expect(Revive.livesRestored, 1);
  });

  test('only one revive is offered per attempt', () {
    expect(Revive.isAvailable(alreadyRevived: false), isTrue);
    expect(Revive.isAvailable(alreadyRevived: true), isFalse);
  });

  test('affordability is judged on the coin balance', () {
    expect(Revive.canAfford(0), isFalse);
    expect(Revive.canAfford(Revive.cost - 1), isFalse);
    expect(Revive.canAfford(Revive.cost), isTrue);
    expect(Revive.canAfford(500), isTrue);
  });

  test('shortBy reports the missing coins and is never negative', () {
    expect(Revive.shortBy(0), Revive.cost);
    expect(Revive.shortBy(Revive.cost - 5), 5);
    expect(Revive.shortBy(Revive.cost), 0);
    expect(Revive.shortBy(10000), 0);
  });
}
