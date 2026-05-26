import 'package:anonym_front_flutter/models/inventory_item_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InventoryItemModel', () {
    test('fromJson parses nested shop and created date', () {
      final model = InventoryItemModel.fromJson({
        'item_id': '1',
        'user_id': 2,
        'article_id': 9.0,
        'active': '1',
        'created_at': '2025-01-01T00:00:00Z',
        'Shop': {
          'article_id': 9,
          'title': 'Frame',
          'type': 'CADRE',
          'amount': 1,
          'content': '/f.png',
        },
      });

      expect(model.itemId, 1);
      expect(model.userId, 2);
      expect(model.articleId, 9);
      expect(model.active, isTrue);
      expect(model.createdAt, isNotNull);
      expect(model.shop?.articleId, 9);
    });

    test('fromJson defaults on invalid values', () {
      final model = InventoryItemModel.fromJson({
        'itemId': 'x',
        'userId': 'y',
        'articleId': 'z',
        'active': 'nope',
        'createdAt': 'x',
      });

      expect(model.itemId, 0);
      expect(model.userId, 0);
      expect(model.articleId, 0);
      expect(model.active, isFalse);
      expect(model.createdAt, isNull);
      expect(model.shop, isNull);
    });
  });
}

