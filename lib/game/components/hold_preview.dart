/// Press and hold on an arrow: once the finger has stayed down for [delay]
/// seconds, that arrow's direction beam is shown until the finger lifts.
///
/// Time is fed in by the caller, so the rules can be tested without Flutter.
final class HoldPreview {
  HoldPreview({this.delay = 0.3});

  final double delay;
  String? _vehicleId;
  var _held = 0.0;

  /// The arrow under the finger, or null when nothing is pressed.
  String? get vehicleId => _vehicleId;

  /// Whether the beam is visible.
  bool get active => _vehicleId != null && _held >= delay;

  void start(String vehicleId) {
    _vehicleId = vehicleId;
    _held = 0;
  }

  /// Advances the hold by [dt] seconds. Returns true on the update where the
  /// beam first becomes visible.
  bool tick(double dt) {
    if (_vehicleId == null || active) return false;
    _held += dt;
    return active;
  }

  void end() => _vehicleId = null;
}
