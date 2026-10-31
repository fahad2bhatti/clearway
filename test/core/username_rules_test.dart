import 'package:clearway/core/username_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts letters, numbers and underscore within 3 to 15 characters', () {
    for (final name in ['abc', 'A_1', 'Fahad_2026', 'a' * 15, '___']) {
      expect(UsernameRules.validate(name), isNull, reason: name);
    }
  });

  test('rejects names that are too short or too long', () {
    expect(UsernameRules.validate(''), UsernameError.tooShort);
    expect(UsernameRules.validate('ab'), UsernameError.tooShort);
    expect(UsernameRules.validate('a' * 16), UsernameError.tooLong);
  });

  test('rejects spaces, symbols and non-English letters', () {
    for (final name in ['a b', 'ab!', 'user-1', 'ab.cd', 'عمر12', 'ab😀']) {
      expect(
        UsernameRules.validate(name),
        UsernameError.invalidCharacters,
        reason: name,
      );
    }
  });

  test('rejects a trailing newline', () {
    expect(UsernameRules.validate('abc\n'), UsernameError.invalidCharacters);
  });
}
