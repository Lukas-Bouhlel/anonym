sealed class PasswordValidationError {
  const PasswordValidationError();
}

final class PasswordTooShort extends PasswordValidationError {
  const PasswordTooShort();
}

final class PasswordMissingLowercase extends PasswordValidationError {
  const PasswordMissingLowercase();
}

final class PasswordMissingUppercase extends PasswordValidationError {
  const PasswordMissingUppercase();
}

final class PasswordMissingNumber extends PasswordValidationError {
  const PasswordMissingNumber();
}

final class PasswordMissingSymbol extends PasswordValidationError {
  const PasswordMissingSymbol();
}

abstract final class PasswordValidators {
  static const int minLength = 12;
  static final RegExp _lowercaseReg = RegExp(r'[a-z]');
  static final RegExp _uppercaseReg = RegExp(r'[A-Z]');
  static final RegExp _numberReg = RegExp(r'[0-9]');
  static final RegExp _symbolReg =
      RegExp(r"""[!@#$%^&*()_\+\-=\[\]{};:'",.<>\/?\\|`~]""");

  static bool hasMinLength(String v) => v.trim().length >= minLength;
  static bool hasLowercase(String v) => _lowercaseReg.hasMatch(v);
  static bool hasUppercase(String v) => _uppercaseReg.hasMatch(v);
  static bool hasNumber(String v) => _numberReg.hasMatch(v);
  static bool hasSymbol(String v) => _symbolReg.hasMatch(v);

  static List<PasswordValidationError> validate(String value) {
    final v = value.trim();
    return [
      if (!hasMinLength(v)) const PasswordTooShort(),
      if (!hasLowercase(v)) const PasswordMissingLowercase(),
      if (!hasUppercase(v)) const PasswordMissingUppercase(),
      if (!hasNumber(v)) const PasswordMissingNumber(),
      if (!hasSymbol(v)) const PasswordMissingSymbol(),
    ];
  }

  static String? validateAsString(String? value) {
    final errors = validate(value?.trim() ?? '');
    if (errors.isEmpty) return null;

    return switch (errors.first) {
      PasswordTooShort() => 'Au moins $minLength caractères requis',
      PasswordMissingLowercase() => 'Au moins une minuscule requise',
      PasswordMissingUppercase() => 'Au moins une majuscule requise',
      PasswordMissingNumber() => 'Au moins un chiffre requis',
      PasswordMissingSymbol() => 'Au moins un symbole requis',
    };
  }
}
