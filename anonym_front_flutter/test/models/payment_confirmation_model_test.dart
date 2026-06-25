import 'package:anonym_front_flutter/models/payment_confirmation_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaymentConfirmationModel', () {
    test('fromJson parses message and nested invoice', () {
      final model = PaymentConfirmationModel.fromJson({
        'message': 'ok',
        'invoice': {
          'id': 1,
          'user_id': 2,
          'article_id': 3,
          'type': 'SHOP',
          'amount': 4,
          'content': 'x',
          'quantity': 1,
        },
      });

      expect(model.message, 'ok');
      expect(model.invoice, isNotNull);
      expect(model.invoice?.id, 1);
    });

    test('fromJson returns empty/default values', () {
      final model = PaymentConfirmationModel.fromJson({});
      expect(model.message, '');
      expect(model.invoice, isNull);
    });
  });
}

