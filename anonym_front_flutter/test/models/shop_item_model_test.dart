import 'package:anonym_front_flutter/models/shop_item_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShopItemModel', () {
    test('fromJson parses numeric/string values', () {
      final model = ShopItemModel.fromJson({
        'article_id': '4',
        'title': 'Aura',
        'type': 'CADRE',
        'amount': 12.0,
        'content': '/assets/aura.png',
      });

      expect(model.articleId, 4);
      expect(model.title, 'Aura');
      expect(model.type, 'CADRE');
      expect(model.amount, 12);
      expect(model.content, isNotEmpty);
    });

    test('fromJson defaults invalid values', () {
      final model = ShopItemModel.fromJson({
        'articleId': 'bad',
        'amount': 'bad',
      });

      expect(model.articleId, 0);
      expect(model.title, '');
      expect(model.type, '');
      expect(model.amount, 0);
      expect(model.content, '');
    });
  });
}

