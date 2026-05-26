import 'package:anonym_front_flutter/models/invoice_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InvoiceModel', () {
    test('fromJson parses aliases and date', () {
      final model = InvoiceModel.fromJson({
        'id': '5',
        'user_id': '6',
        'article_id': 7.0,
        'type': 'SHOP',
        'amount': '99',
        'content': 'Commande',
        'quantity': 3,
        'createdAt': '2025-02-02T12:00:00Z',
      });

      expect(model.id, 5);
      expect(model.userId, 6);
      expect(model.articleId, 7);
      expect(model.type, 'SHOP');
      expect(model.amount, 99);
      expect(model.content, 'Commande');
      expect(model.quantity, 3);
      expect(model.createdAt, isNotNull);
    });

    test('fromJson defaults invalid values', () {
      final model = InvoiceModel.fromJson({
        'id': 'bad',
        'userId': 'bad',
        'articleId': 'bad',
        'amount': 'bad',
        'quantity': 'bad',
        'createdAt': 'bad-date',
      });

      expect(model.id, 0);
      expect(model.userId, 0);
      expect(model.articleId, 0);
      expect(model.amount, 0);
      expect(model.quantity, 0);
      expect(model.createdAt, isNull);
    });
  });
}

