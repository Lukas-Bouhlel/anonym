import 'password_validators.dart';

/// Règles de validation utilisées dans les formulaires d'authentification.
abstract final class AuthValidators {
  /// Vérifie qu'une valeur obligatoire est présente.
  static String? requiredField(String? value, {String label = 'Ce champ'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label est requis';
    }
    return null;
  }

  /// Vérifie le format minimum d'un email.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email requis';
    }

    final email = value.trim();
    if (!email.contains('@')) {
      return 'Email invalide';
    }
    return null;
  }

  /// Vérifie un mot de passe (mode simple ou strict).
  static String? password(String? value, {bool strict = false}) {
    if (value == null || value.isEmpty) {
      return 'Mot de passe requis';
    }

    if (!strict) return null;
    return PasswordValidators.validateAsString(value);
  }
}
