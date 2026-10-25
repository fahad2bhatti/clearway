/// Spending coins to get back into a board after the last life is lost.
///
/// One revive is allowed per attempt at a board, so coins cannot be turned
/// into unlimited lives.
abstract final class Revive {
  static const cost = 30;
  static const livesRestored = 1;

  /// Whether another revive may still be offered on this attempt.
  static bool isAvailable({required bool alreadyRevived}) => !alreadyRevived;

  static bool canAfford(int coins) => coins >= cost;

  /// How many more coins are needed, never negative.
  static int shortBy(int coins) => coins >= cost ? 0 : cost - coins;
}
