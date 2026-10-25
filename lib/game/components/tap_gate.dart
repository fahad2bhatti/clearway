/// Decides whether a touch on the board is a deliberate tap.
///
/// A tap is one finger that lifts quickly without moving. A long press, a drag
/// (panning a zoomed board) and two fingers (pinch zoom) are not taps, so they
/// never move a bus or cost a life.
///
/// Positions are device pixels and the clock is injectable, so the rules can be
/// tested without Flutter.
final class TapGate {
  TapGate({
    this.maxPress = const Duration(milliseconds: 400),
    this.slop = 14,
    this.staleAfter = const Duration(seconds: 10),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// The longest a finger may stay down and still count as a tap.
  final Duration maxPress;

  /// How far, in device pixels, a finger may drift and still count as a tap.
  final double slop;

  /// A finger whose release was never reported is forgotten after this long,
  /// so one lost event cannot make every later tap look like a pinch.
  final Duration staleAfter;

  final DateTime Function() _clock;
  final Map<int, _Touch> _touches = {};
  var _multiTouch = false;

  /// A finger touched the board.
  void down(int pointer, double x, double y) {
    final now = _clock();
    _touches.removeWhere((_, touch) => now.difference(touch.at) > staleAfter);
    if (_touches.isEmpty) _multiTouch = false;
    if (_touches.keys.any((id) => id != pointer)) _multiTouch = true;
    _touches[pointer] = _Touch(x, y, now);
  }

  /// A finger lifted. Returns true when that release completes a tap.
  bool up(int pointer, double x, double y) {
    final touch = _touches.remove(pointer);
    final multiTouch = _multiTouch;
    if (_touches.isEmpty) _multiTouch = false;
    if (touch == null || multiTouch) return false;
    if (_clock().difference(touch.at) > maxPress) return false;
    final dx = x - touch.x;
    final dy = y - touch.y;
    return dx * dx + dy * dy <= slop * slop;
  }

  /// The gesture was taken over (for example by a pan) or aborted.
  void cancel(int pointer) {
    _touches.remove(pointer);
    if (_touches.isEmpty) _multiTouch = false;
  }
}

final class _Touch {
  const _Touch(this.x, this.y, this.at);

  final double x;
  final double y;
  final DateTime at;
}
