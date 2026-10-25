import 'package:clearway/game/components/tap_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var now = DateTime.utc(2026, 10, 25);
  void wait(int milliseconds) =>
      now = now.add(Duration(milliseconds: milliseconds));

  late TapGate gate;
  setUp(() {
    now = DateTime.utc(2026, 10, 25);
    gate = TapGate(clock: () => now);
  });

  group('single finger', () {
    test('a quick, still touch is a tap', () {
      gate.down(1, 100, 100);
      wait(120);
      expect(gate.up(1, 100, 100), isTrue);
    });

    test('a long press is not a tap', () {
      gate.down(1, 100, 100);
      wait(900);
      expect(gate.up(1, 100, 100), isFalse);
    });

    test('exactly the longest allowed press is still a tap', () {
      gate.down(1, 100, 100);
      wait(400);
      expect(gate.up(1, 100, 100), isTrue);
      gate.down(2, 100, 100);
      wait(401);
      expect(gate.up(2, 100, 100), isFalse);
    });

    test('dragging more than the slop is not a tap', () {
      gate.down(1, 100, 100);
      wait(100);
      expect(gate.up(1, 100, 130), isFalse);
    });

    test('a small wobble inside the slop is still a tap', () {
      gate.down(1, 100, 100);
      wait(100);
      expect(gate.up(1, 105, 108), isTrue);
    });

    test('a cancelled touch can never become a tap', () {
      gate.down(1, 100, 100);
      gate.cancel(1);
      expect(gate.up(1, 100, 100), isFalse);
    });

    test('a release with no matching touch is ignored', () {
      expect(gate.up(7, 0, 0), isFalse);
    });

    test('each fresh touch is judged on its own', () {
      gate.down(1, 100, 100);
      wait(900);
      expect(gate.up(1, 100, 100), isFalse);
      gate.down(1, 100, 100);
      wait(100);
      expect(gate.up(1, 100, 100), isTrue);
    });
  });

  group('two fingers (pinch)', () {
    test('neither finger of a pinch is a tap', () {
      gate.down(1, 100, 100);
      gate.down(2, 200, 200);
      wait(100);
      expect(gate.up(1, 100, 100), isFalse);
      expect(gate.up(2, 200, 200), isFalse);
    });

    test('the second finger alone does not count either', () {
      gate.down(1, 100, 100);
      wait(50);
      gate.down(2, 200, 200);
      wait(50);
      expect(gate.up(2, 200, 200), isFalse);
      expect(gate.up(1, 100, 100), isFalse);
    });

    test('a tap right after a pinch ended works again', () {
      gate.down(1, 100, 100);
      gate.down(2, 200, 200);
      gate.up(1, 100, 100);
      gate.up(2, 200, 200);
      wait(500);
      gate.down(3, 150, 150);
      wait(100);
      expect(gate.up(3, 150, 150), isTrue);
    });

    test('cancelling both fingers of a pinch clears it', () {
      gate.down(1, 100, 100);
      gate.down(2, 200, 200);
      gate.cancel(1);
      gate.cancel(2);
      gate.down(3, 150, 150);
      wait(100);
      expect(gate.up(3, 150, 150), isTrue);
    });
  });

  group('lost events', () {
    test('a finger that never reported its release is forgotten', () {
      gate.down(1, 100, 100);
      wait(11000);
      gate.down(2, 150, 150);
      wait(100);
      expect(gate.up(2, 150, 150), isTrue);
    });

    test('a repeated down for the same finger is not a second finger', () {
      gate.down(1, 100, 100);
      gate.down(1, 100, 100);
      wait(100);
      expect(gate.up(1, 100, 100), isTrue);
    });
  });
}
