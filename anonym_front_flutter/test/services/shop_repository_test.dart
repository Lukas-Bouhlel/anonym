import 'dart:io';

import 'package:anonym_front_flutter/services/shop_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'repository_test_utils.dart';

void main() {
  group('ShopRepository', () {
    late MockDio dio;
    late ShopRepository repository;

    setUp(() {
      dio = MockDio();
      repository = ShopRepository(dio);
    });

    test('readAll and readById parse items', () async {
      when(() => dio.get<List<dynamic>>('/api/shop')).thenAnswer(
        (_) async => dioResponse<List<dynamic>>([
          {
            'article_id': 1,
            'title': 'Aura',
            'type': 'CADRE',
            'amount': 5,
            'content': '/a.png',
          },
        ], path: '/api/shop'),
      );
      when(
        () => dio.get<Map<String, dynamic>>('/api/shop/1'),
      ).thenAnswer(
        (_) async => dioResponse<Map<String, dynamic>>({
          'article_id': 1,
          'title': 'Aura',
          'type': 'CADRE',
          'amount': 5,
          'content': '/a.png',
        }, path: '/api/shop/1'),
      );

      final all = await repository.readAll();
      final one = await repository.readById(1);
      expect(all, hasLength(1));
      expect(one.articleId, 1);
    });

    test('adminCreate adminUpdate and adminDelete call endpoints', () async {
      final tempDir = await Directory.systemTemp.createTemp('shop_repo_test_');
      addTearDown(() async {
        await tempDir.delete(recursive: true);
      });
      final imagePath = '${tempDir.path}/shop.png';
      await File(imagePath).writeAsBytes([1, 2, 3]);

      when(
        () => dio.post<Map<String, dynamic>>(
          '/api/shop/admin/',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => dioResponse<Map<String, dynamic>>({
          'article_id': 2,
          'title': 'Created',
          'type': 'CADRE',
          'amount': 10,
          'content': '/c.png',
        }, path: '/api/shop/admin/'),
      );
      when(
        () => dio.put<Map<String, dynamic>>(
          '/api/shop/admin/2',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => dioResponse<Map<String, dynamic>>({
          'article_id': 2,
          'title': 'Updated',
          'type': 'CADRE',
          'amount': 12,
          'content': '/u.png',
        }, path: '/api/shop/admin/2'),
      );
      when(
        () => dio.delete<void>('/api/shop/admin/2'),
      ).thenAnswer((_) async => dioResponse<void>(null, path: '/api/shop/admin/2'));

      final created = await repository.adminCreate(
        datas: {'title': 'Created'},
        imageFilePath: imagePath,
      );
      final updated = await repository.adminUpdate(
        articleId: 2,
        datas: {'title': 'Updated'},
        imageFilePath: imagePath,
      );
      await repository.adminDelete(2);

      expect(created.title, 'Created');
      expect(updated.title, 'Updated');
    });
  });
}

