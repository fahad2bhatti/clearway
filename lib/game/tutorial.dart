/// First-time help covers the first [levels] levels of the main progression.
///
/// Once the player has won the last guided level, the help (tips and the
/// pointing hand) stops, even when they replay those levels later.
abstract final class Tutorial {
  static const levels = 3;

  /// True when level [number] is one of the guided levels.
  static bool covers(int number) => number >= 1 && number <= levels;

  /// True when a player whose next unlocked level is [unlockedLevel] has
  /// already won every guided level.
  static bool finishedBy(int unlockedLevel) => unlockedLevel > levels;

  /// Whether level [number] should show first-time help to this player.
  static bool helps(int number, {required bool done}) =>
      !done && covers(number);
}
