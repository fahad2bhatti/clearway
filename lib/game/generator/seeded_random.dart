/// Tiny portable PRNG (xorshift32). It only uses 32-bit shifts, xors and
/// masks, so the same seed gives the same sequence on every platform and
/// Dart version. That keeps "level N is always the same puzzle" true.
final class SeededRandom {
  SeededRandom(int seed) : _state = _scramble(seed) {
    for (var i = 0; i < 12; i++) {
      nextInt32();
    }
  }

  static const _mask = 0xFFFFFFFF;

  int _state;

  static int _scramble(int seed) {
    var x = (seed ^ (seed >> 32)) & _mask;
    x = (x + 0x9E3779B9) & _mask;
    return x == 0 ? 0x6D2B79F5 : x;
  }

  int nextInt32() {
    var x = _state;
    x ^= (x << 13) & _mask;
    x ^= x >> 17;
    x ^= (x << 5) & _mask;
    _state = x;
    return x;
  }

  /// A value in `0 <= value < max`.
  int nextInt(int max) {
    if (max <= 0) throw ArgumentError.value(max, 'max', 'must be positive');
    return nextInt32() % max;
  }

  /// True with the given percent chance (0 to 100).
  bool chance(int percent) => nextInt(100) < percent;

  void shuffle<T>(List<T> items) {
    for (var i = items.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final tmp = items[i];
      items[i] = items[j];
      items[j] = tmp;
    }
  }
}
