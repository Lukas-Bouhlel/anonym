import 'password_validators.dart';

class AuthValidators {
  const AuthValidators._();

  static String? requiredField(String? value, {String label = 'Ce champ'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label est requis';
    }
    return null;
  }

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

  static String? password(String? value, {bool strict = false}) {
    if (value == null || value.isEmpty) {
      return 'Mot de passe requis';
    }

    if (!strict) return null;
    return PasswordValidators.validateAsString(value);
  }
}
