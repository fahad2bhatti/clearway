import 'package:clearway/game/tutorial.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only the first guided levels are covered', () {
    expect(Tutorial.covers(0), isFalse);
    for (var number = 1; number <= Tutorial.levels; number++) {
      expect(Tutorial.covers(number), isTrue, reason: 'level $number');
    }
    expect(Tutorial.covers(Tutorial.levels + 1), isFalse);
    expect(Tutorial.covers(80), isFalse);
  });

  test('a player who unlocked level 4 or more has finished the tutorial', () {
    expect(Tutorial.finishedBy(1), isFalse);
    expect(Tutorial.finishedBy(Tutorial.levels), isFalse);
    expect(Tutorial.finishedBy(Tutorial.levels + 1), isTrue);
    expect(Tutorial.finishedBy(80), isTrue);
  });

  test('help shows on guided levels until the tutorial is done', () {
    for (var number = 1; number <= Tutorial.levels; number++) {
      expect(Tutorial.helps(number, done: false), isTrue);
      expect(Tutorial.helps(number, done: true), isFalse);
    }
    expect(Tutorial.helps(Tutorial.levels + 1, done: false), isFalse);
    expect(Tutorial.helps(10, done: false), isFalse);
  });
}
