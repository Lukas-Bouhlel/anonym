/// Type racine des erreurs de validation de mot de passe.
sealed class PasswordValidationError {
  const PasswordValidationError();
}

/// Erreur: longueur minimale non respectée.
final class PasswordTooShort extends PasswordValidationError {
  const PasswordTooShort();
}

/// Erreur: aucune minuscule détectée.
final class PasswordMissingLowercase extends PasswordValidationError {
  const PasswordMissingLowercase();
}

/// Erreur: aucune majuscule détectée.
final class PasswordMissingUppercase extends PasswordValidationError {
  const PasswordMissingUppercase();
}

/// Erreur: aucun chiffre détecté.
final class PasswordMissingNumber extends PasswordValidationError {
  const PasswordMissingNumber();
}

/// Erreur: aucun symbole détecté.
final class PasswordMissingSymbol extends PasswordValidationError {
  const PasswordMissingSymbol();
}

/// Règles de validation du mot de passe (policy sécurité).
abstract final class PasswordValidators {
  static const int minLength = 12;
  static final RegExp _lowercaseReg = RegExp(r'[a-z]');
  static final RegExp _uppercaseReg = RegExp(r'[A-Z]');
  static final RegExp _numberReg = RegExp(r'[0-9]');
  static final RegExp _symbolReg = RegExp(
    r"""[!@#$%^&*()_\+\-=\[\]{};:'",.<>\/?\\|`~]""",
  );

  /// Vérifie la longueur minimale.
  static bool hasMinLength(String v) => v.trim().length >= minLength;
  /// Vérifie la présence d'au moins une minuscule.
  static bool hasLowercase(String v) => _lowercaseReg.hasMatch(v);
  /// Vérifie la présence d'au moins une majuscule.
  static bool hasUppercase(String v) => _uppercaseReg.hasMatch(v);
  /// Vérifie la présence d'au moins un chiffre.
  static bool hasNumber(String v) => _numberReg.hasMatch(v);
  /// Vérifie la présence d'au moins un symbole.
  static bool hasSymbol(String v) => _symbolReg.hasMatch(v);

  /// Retourne la liste des erreurs de validation détectées.
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

  /// Retourne le premier message d'erreur lisible, sinon `null`.
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
