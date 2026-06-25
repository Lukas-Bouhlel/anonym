import 'package:anonym_front_flutter/services/inventory_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'repository_test_utils.dart';

void main() {
  group('InventoryRepository', () {
    late MockDio dio;
    late InventoryRepository repository;

    setUp(() {
      dio = MockDio();
      repository = InventoryRepository(dio);
    });

    test('readAll returns parsed items', () async {
      when(() => dio.get<List<dynamic>>('/api/inventory')).thenAnswer(
        (_) async => dioResponse<List<dynamic>>([
          {
            'item_id': 1,
            'user_id': 2,
            'article_id': 3,
            'active': true,
          },
        ], path: '/api/inventory'),
      );

      final items = await repository.readAll();
      expect(items, hasLength(1));
      expect(items.first.itemId, 1);
    });

    test('readAll returns empty list on 404', () async {
      when(() => dio.get<List<dynamic>>('/api/inventory')).thenThrow(
        dioException(path: '/api/inventory', statusCode: 404),
      );

      final items = await repository.readAll();
      expect(items, isEmpty);
    });

    test('readAll rethrows non-404 errors', () async {
      when(() => dio.get<List<dynamic>>('/api/inventory')).thenThrow(
        dioException(path: '/api/inventory', statusCode: 500),
      );

      await expectLater(repository.readAll(), throwsA(isA<DioException>()));
    });

    test('readById updateStatus and admin endpoints parse payloads', () async {
      when(
        () => dio.get<Map<String, dynamic>>('/api/inventory/7'),
      ).thenAnswer(
        (_) async => dioResponse<Map<String, dynamic>>({
          'item_id': 7,
          'user_id': 1,
          'article_id': 2,
          'active': false,
        }, path: '/api/inventory/7'),
      );
      when(
        () => dio.put<Map<String, dynamic>>(
          '/api/inventory/7',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => dioResponse<Map<String, dynamic>>({
          'item_id': 7,
          'user_id': 1,
          'article_id': 2,
          'active': true,
        }, path: '/api/inventory/7'),
      );
      when(
        () => dio.get<List<dynamic>>('/api/inventory/admin/inventories'),
      ).thenAnswer(
        (_) async => dioResponse<List<dynamic>>([
          {'item_id': 1, 'user_id': 1, 'article_id': 9, 'active': true},
        ], path: '/api/inventory/admin/inventories'),
      );
      when(
        () => dio.post<Map<String, dynamic>>(
          '/api/inventory/admin/',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => dioResponse<Map<String, dynamic>>({
          'item_id': 11,
          'user_id': 1,
          'article_id': 9,
          'active': true,
        }, path: '/api/inventory/admin/'),
      );
      when(
        () => dio.put<Map<String, dynamic>>(
          '/api/inventory/admin/11',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => dioResponse<Map<String, dynamic>>({
          'item_id': 11,
          'user_id': 2,
          'article_id': 10,
          'active': false,
        }, path: '/api/inventory/admin/11'),
      );
      when(
        () => dio.delete<void>('/api/inventory/admin/11'),
      ).thenAnswer((_) async => dioResponse<void>(null, path: '/api/inventory/admin/11'));

      final byId = await repository.readById(7);
      final updated = await repository.updateStatus(itemId: 7, active: true);
      final adminAll = await repository.adminReadAll();
      final adminCreated = await repository.adminCreate(userId: 1, articleId: 9);
      final adminUpdated = await repository.adminUpdate(
        itemId: 11,
        userId: 2,
        articleId: 10,
      );
      await repository.adminDelete(11);

      expect(byId.itemId, 7);
      expect(updated.active, isTrue);
      expect(adminAll, hasLength(1));
      expect(adminCreated.itemId, 11);
      expect(adminUpdated.userId, 2);
    });
  });
}

