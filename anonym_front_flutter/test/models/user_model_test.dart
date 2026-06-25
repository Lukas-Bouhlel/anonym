import 'package:anonym_front_flutter/models/inventory_item_model.dart';
import 'package:anonym_front_flutter/models/shop_item_model.dart';
import 'package:anonym_front_flutter/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserModel', () {
    test('fromJson parses aliases and nested inventories list', () {
      final user = UserModel.fromJson({
        'user_id': '42',
        'username': 'neo',
        'email': 'neo@test.dev',
        'level': 0,
        'created_at': '2024-02-01T10:11:12Z',
        'avatar': '/avatars/neo.png',
        'bio': 'bio',
        'roles': 'ADMIN',
        'presence_status': 'online',
        'allow_non_friend_dms': '0',
        'inventories': [
          {
            'item_id': 5,
            'user_id': 42,
            'article_id': 77,
            'active': true,
            'shop': {
              'article_id': 77,
              'title': 'Cadre',
              'type': 'CADRE',
              'amount': 1,
              'content': '/frames/a.png',
            },
          },
        ],
      });

      expect(user.id, 42);
      expect(user.username, 'neo');
      expect(user.email, 'neo@test.dev');
      expect(user.level, 1);
      expect(user.createdAt, isNotNull);
      expect(user.bio, 'bio');
      expect(user.roles, 'ADMIN');
      expect(user.isAdmin, isTrue);
      expect(user.presenceStatus, 'online');
      expect(user.allowNonFriendDms, isFalse);
      expect(user.inventories, hasLength(1));
      expect(user.inventories.first.shop?.content, isNotEmpty);
    });

    test('fromJson handles fallback defaults and inventory map', () {
      final user = UserModel.fromJson({
        'id': 'bad',
        'username': null,
        'email': null,
        'allowNonFriendDms': 1,
        'Inventory': {
          'item_id': '8',
          'user_id': '1',
          'article_id': '2',
          'active': 'true',
        },
      });

      expect(user.id, 0);
      expect(user.username, '');
      expect(user.email, '');
      expect(user.level, 1);
      expect(user.allowNonFriendDms, isTrue);
      expect(user.inventories, hasLength(1));
      expect(user.inventories.first.itemId, 8);
    });

    test('copyWith overrides selected values', () {
      const original = UserModel(
        id: 1,
        username: 'a',
        email: 'a@test.dev',
        inventories: [
          InventoryItemModel(
            itemId: 10,
            userId: 1,
            articleId: 2,
            active: true,
            shop: ShopItemModel(
              articleId: 2,
              title: 'Cadre',
              type: 'CADRE',
              amount: 3,
              content: 'x',
            ),
          ),
        ],
      );

      final updated = original.copyWith(
        username: 'b',
        level: 9,
        allowNonFriendDms: false,
      );

      expect(updated.id, 1);
      expect(updated.username, 'b');
      expect(updated.level, 9);
      expect(updated.allowNonFriendDms, isFalse);
      expect(updated.inventories, hasLength(1));
    });
  });
}

