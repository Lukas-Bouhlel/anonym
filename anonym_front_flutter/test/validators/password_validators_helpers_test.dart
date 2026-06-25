import 'package:anonym_front_flutter/validators/password_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PasswordValidators helper predicates', () {
    test('hasMinLength trims value before checking length', () {
      const raw = '   123456789012   ';
      expect(PasswordValidators.hasMinLength(raw), isTrue);
    });

    test('hasLowercase/Uppercase/Number/Symbol detect expected classes', () {
      expect(PasswordValidators.hasLowercase('ABCd'), isTrue);
      expect(PasswordValidators.hasUppercase('abC1'), isTrue);
      expect(PasswordValidators.hasNumber('abc9X'), isTrue);
      expect(PasswordValidators.hasSymbol('abc#123'), isTrue);
    });
  });
}

