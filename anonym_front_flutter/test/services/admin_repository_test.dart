import 'dart:io';

import 'package:anonym_front_flutter/services/admin_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'repository_test_utils.dart';

void main() {
  group('AdminRepository', () {
    late MockDio dio;
    late AdminRepository repository;

    setUp(() {
      dio = MockDio();
      repository = AdminRepository(dio);
    });

    test('createUser and updateUser parse responses', () async {
      final tempDir = await Directory.systemTemp.createTemp('admin_repo_test_');
      addTearDown(() async {
        await tempDir.delete(recursive: true);
      });
      final imagePath = '${tempDir.path}/avatar.png';
      await File(imagePath).writeAsBytes([1, 2, 3]);

      when(
        () => dio.post<Map<String, dynamic>>(
          '/api/admin/users',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => dioResponse<Map<String, dynamic>>({
          'id': 1,
          'username': 'created',
          'email': 'c@test.dev',
        }, path: '/api/admin/users'),
      );
      when(
        () => dio.put<Map<String, dynamic>>(
          '/api/admin/users/1',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => dioResponse<Map<String, dynamic>>({
          'id': 1,
          'username': 'updated',
          'email': 'u@test.dev',
        }, path: '/api/admin/users/1'),
      );

      final created = await repository.createUser(
        datas: {'username': 'created'},
        avatarFilePath: imagePath,
      );
      final updated = await repository.updateUser(
        userId: 1,
        datas: {'username': 'updated'},
        avatarFilePath: imagePath,
      );

      expect(created.username, 'created');
      expect(updated.username, 'updated');
    });

    test('deleteUser and report call expected endpoints', () async {
      when(
        () => dio.delete<void>('/api/admin/users/7'),
      ).thenAnswer((_) async => dioResponse<void>(null, path: '/api/admin/users/7'));
      when(
        () => dio.post<void>(
          '/api/admin/report',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => dioResponse<void>(null, path: '/api/admin/report'));

      await repository.deleteUser(7);
      await repository.report(
        email: 'a@test.dev',
        type: 'feedback',
        content: 'hello',
      );

      verify(() => dio.delete<void>('/api/admin/users/7')).called(1);
      verify(
        () => dio.post<void>('/api/admin/report', data: any(named: 'data')),
      ).called(1);
      expect(repository.apiDocsPath(), '/api/admin/api-docs');
    });
  });
}

