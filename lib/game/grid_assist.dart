import 'engine/game_level.dart';
import 'engine/move_validator.dart';
import 'engine/vehicle.dart';

/// Grid Assist power-up: highlights every arrow that can leave right now.
///
/// The first use on a level is free; turning it on again after that needs a
/// rewarded ad. While it is on, the highlight is recomputed from the arrows
/// that are left, so it always matches the board.
class GridAssist {
  GridAssist({this.active = false, this.freeUsed = false});

  factory GridAssist.fromJson(Map<String, dynamic> json) => GridAssist(
    active: json['assistEnabled'] == true,
    freeUsed: json['assistUsed'] == true,
  );

  bool active;
  bool freeUsed;

  /// Whether the next activation costs nothing.
  bool get nextUseIsFree => !freeUsed;

  void turnOn() {
    active = true;
    freeUsed = true;
  }

  void turnOff() => active = false;

  /// Ids of the arrows to highlight; empty while the assist is off.
  Set<String> highlight(GameLevel level, Iterable<Vehicle> remaining) => active
      ? {
          for (final vehicle in MoveValidator.safeVehicles(level, remaining))
            vehicle.id,
        }
      : const {};

  Map<String, bool> toJson() => {
    'assistEnabled': active,
    'assistUsed': freeUsed,
  };
}
