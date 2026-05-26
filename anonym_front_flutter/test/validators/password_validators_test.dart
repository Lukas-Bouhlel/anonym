import 'package:anonym_front_flutter/validators/password_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PasswordValidators.validate', () {
    test('returns all expected errors for a weak password', () {
      final errors = PasswordValidators.validate('abc');

      expect(errors, hasLength(4));
      expect(errors.whereType<PasswordTooShort>(), isNotEmpty);
      expect(errors.whereType<PasswordMissingUppercase>(), isNotEmpty);
      expect(errors.whereType<PasswordMissingNumber>(), isNotEmpty);
      expect(errors.whereType<PasswordMissingSymbol>(), isNotEmpty);
    });

    test('returns no error for a valid password', () {
      final errors = PasswordValidators.validate('Str0ng!PassWord');
      expect(errors, isEmpty);
    });
  });

  group('PasswordValidators.validateAsString', () {
    test('returns first error message for too short password', () {
      final message = PasswordValidators.validateAsString('A1!short');

      expect(message, contains('Au moins ${PasswordValidators.minLength}'));
      expect(message, contains('requis'));
    });

    test('returns lowercase error when lowercase is missing', () {
      final message = PasswordValidators.validateAsString('PASSWORD123!');
      expect(message, 'Au moins une minuscule requise');
    });

    test('returns uppercase error when uppercase is missing', () {
      final message = PasswordValidators.validateAsString('password123!');
      expect(message, 'Au moins une majuscule requise');
    });

    test('returns number error when number is missing', () {
      final message = PasswordValidators.validateAsString('PasswordOnly!');
      expect(message, 'Au moins un chiffre requis');
    });

    test('returns symbol error when symbol is missing', () {
      final message = PasswordValidators.validateAsString('Password1234');
      expect(message, 'Au moins un symbole requis');
    });

    test('returns null for a compliant password', () {
      final message = PasswordValidators.validateAsString('Compliant#123');
      expect(message, isNull);
    });
  });
}
