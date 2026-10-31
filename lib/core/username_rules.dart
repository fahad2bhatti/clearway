enum UsernameError { tooShort, tooLong, invalidCharacters }

/// Client-side username rules. The server must enforce the same rules.
abstract final class UsernameRules {
  static const minLength = 3;
  static const maxLength = 15;
  static final _allowed = RegExp(r'^[A-Za-z0-9_]*$');

  static UsernameError? validate(String value) {
    if (!_allowed.hasMatch(value)) return UsernameError.invalidCharacters;
    if (value.length < minLength) return UsernameError.tooShort;
    if (value.length > maxLength) return UsernameError.tooLong;
    return null;
  }
}
