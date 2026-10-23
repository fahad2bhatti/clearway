/// Compact, index-preserving encoding for the stars earned in each level.
/// A character at index zero represents level 1; zero stars are stored as `0`.
abstract final class ProgressCodec {
  static String encode(Map<int, int> stars, {int throughLevel = 0}) {
    if (throughLevel < 0) {
      throw ArgumentError.value(throughLevel, 'throughLevel');
    }
    var length = throughLevel;
    for (final entry in stars.entries) {
      if (entry.key < 1) {
        throw ArgumentError.value(entry.key, 'level', 'Levels start at 1.');
      }
      if (entry.value < 0 || entry.value > 3) {
        throw ArgumentError.value(entry.value, 'stars', 'Expected 0 to 3.');
      }
      if (entry.key > length) length = entry.key;
    }

    final result = List<String>.filled(length, '0');
    for (final entry in stars.entries) {
      result[entry.key - 1] = '${entry.value}';
    }
    return result.join();
  }

  /// Invalid characters are skipped while retaining their index, so later
  /// valid entries remain associated with the same level numbers.
  static Map<int, int> decode(String starsCode) {
    final stars = <int, int>{};
    var index = 0;
    for (final rune in starsCode.runes) {
      if (rune >= 0x30 && rune <= 0x33) {
        final count = rune - 0x30;
        if (count > 0) stars[index + 1] = count;
      }
      index++;
    }
    return stars;
  }
}
