/// Remembers the last blocked tap so tapping the same stuck arrow again does
/// not cost another life while the board has not changed.
class BlockedTapGuard {
  String? _vehicleId;
  var _remaining = -1;

  /// Whether [vehicleId] is the last blocked arrow and nothing has left the
  /// board of [remaining] arrows since.
  bool isRepeat(String vehicleId, int remaining) =>
      _vehicleId == vehicleId && _remaining == remaining;

  void record(String vehicleId, int remaining) {
    _vehicleId = vehicleId;
    _remaining = remaining;
  }

  /// Call when an arrow leaves or an undo changes the board.
  void reset() => _vehicleId = null;
}
