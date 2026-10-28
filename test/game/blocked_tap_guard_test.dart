import 'package:clearway/game/blocked_tap_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the first blocked tap is never a repeat', () {
    expect(BlockedTapGuard().isRepeat('a', 10), isFalse);
  });

  test('the same arrow on an unchanged board is a repeat', () {
    final guard = BlockedTapGuard()..record('a', 10);
    expect(guard.isRepeat('a', 10), isTrue);
    expect(guard.isRepeat('a', 10), isTrue);
  });

  test('a different blocked arrow is not a repeat', () {
    final guard = BlockedTapGuard()..record('a', 10);
    expect(guard.isRepeat('b', 10), isFalse);
  });

  test('an arrow leaving the board ends the repeat', () {
    final guard = BlockedTapGuard()..record('a', 10);
    expect(guard.isRepeat('a', 9), isFalse);
  });

  test('reset ends the repeat even if the arrow count matches again', () {
    final guard = BlockedTapGuard()
      ..record('a', 10)
      ..reset();
    expect(guard.isRepeat('a', 10), isFalse);
  });

  test('recording another arrow replaces the remembered one', () {
    final guard = BlockedTapGuard()
      ..record('a', 10)
      ..record('b', 10);
    expect(guard.isRepeat('a', 10), isFalse);
    expect(guard.isRepeat('b', 10), isTrue);
  });
}
