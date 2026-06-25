import 'package:anonym_front_flutter/validators/auth_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthValidators.requiredField', () {
    test('returns error for empty value', () {
      final message = AuthValidators.requiredField('   ', label: 'Nom');
      expect(message, 'Nom est requis');
    });

    test('returns null for non-empty value', () {
      final message = AuthValidators.requiredField('Lukas');
      expect(message, isNull);
    });
  });

  group('AuthValidators.email', () {
    test('returns email required on empty value', () {
      expect(AuthValidators.email(''), 'Email requis');
    });

    test('returns invalid message when missing @', () {
      expect(AuthValidators.email('user.example.com'), 'Email invalide');
    });

    test('returns null for valid email', () {
      expect(AuthValidators.email('user@example.com'), isNull);
    });
  });

  group('AuthValidators.password', () {
    test('returns required message for empty password', () {
      expect(AuthValidators.password(''), 'Mot de passe requis');
    });

    test('does not enforce strict rules by default', () {
      expect(AuthValidators.password('short'), isNull);
    });

    test('enforces strict rules when enabled', () {
      final message = AuthValidators.password('short', strict: true);
      expect(message, isNotNull);
    });

    test('accepts a strong password in strict mode', () {
      final message = AuthValidators.password('Compliant#123', strict: true);
      expect(message, isNull);
    });
  });
}
