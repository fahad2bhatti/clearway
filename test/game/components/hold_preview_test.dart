import 'package:clearway/game/components/hold_preview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nothing is shown before an arrow is pressed', () {
    final hold = HoldPreview();
    expect(hold.active, isFalse);
    expect(hold.vehicleId, isNull);
    expect(hold.tick(1), isFalse);
  });

  test('the beam appears only after the hold delay', () {
    final hold = HoldPreview(delay: 0.3)..start('a');
    expect(hold.vehicleId, 'a');
    expect(hold.tick(0.1), isFalse);
    expect(hold.active, isFalse);
    expect(hold.tick(0.1), isFalse);
    expect(hold.tick(0.15), isTrue);
    expect(hold.active, isTrue);
  });

  test('tick reports the moment of appearing only once', () {
    final hold = HoldPreview(delay: 0.3)..start('a');
    expect(hold.tick(0.4), isTrue);
    expect(hold.tick(0.4), isFalse);
    expect(hold.active, isTrue);
  });

  test('lifting the finger hides the beam and ignores later ticks', () {
    final hold = HoldPreview(delay: 0.3)..start('a');
    hold.tick(0.4);
    hold.end();
    expect(hold.active, isFalse);
    expect(hold.vehicleId, isNull);
    expect(hold.tick(1), isFalse);
  });

  test('pressing another arrow restarts the delay', () {
    final hold = HoldPreview(delay: 0.3)..start('a');
    hold.tick(0.4);
    hold.start('b');
    expect(hold.vehicleId, 'b');
    expect(hold.active, isFalse);
    expect(hold.tick(0.35), isTrue);
  });
}
