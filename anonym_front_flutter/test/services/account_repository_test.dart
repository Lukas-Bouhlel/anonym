import 'dart:typed_data';

import 'package:anonym_front_flutter/services/account_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'repository_test_utils.dart';

void main() {
  group('AccountRepository', () {
    late MockDio dio;
    late AccountRepository repository;

    setUp(() {
      dio = MockDio();
      repository = AccountRepository(dio);
    });

    test('readAccount parses user payload', () async {
      when(
        () => dio.get<Map<String, dynamic>>('/api/account'),
      ).thenAnswer(
        (_) async => dioResponse<Map<String, dynamic>>({
          'id': 1,
          'username': 'neo',
          'email': 'neo@test.dev',
        }, path: '/api/account'),
      );

      final result = await repository.readAccount();
      expect(result.id, 1);
      expect(result.username, 'neo');
    });

    test('readAllUsers maps only json entries', () async {
      when(
        () => dio.get<List<dynamic>>('/api/account/discoverable-users'),
      ).thenAnswer(
        (_) async => dioResponse<List<dynamic>>([
          {'id': 1, 'username': 'a', 'email': 'a@test.dev'},
          'skip',
          {'id': 2, 'username': 'b', 'email': 'b@test.dev'},
        ], path: '/api/account/discoverable-users'),
      );

      final users = await repository.readAllUsers();
      expect(users, hasLength(2));
      expect(users.first.id, 1);
      expect(users.last.id, 2);
    });

    test('readUserById hits endpoint with id', () async {
      when(
        () => dio.get<Map<String, dynamic>>('/api/account/42'),
      ).thenAnswer(
        (_) async => dioResponse<Map<String, dynamic>>({
          'id': 42,
          'username': 'u42',
          'email': 'u42@test.dev',
        }, path: '/api/account/42'),
      );

      final result = await repository.readUserById(42);
      expect(result.id, 42);
    });

    test('updateProfile sends multipart request and parses response', () async {
      when(
        () => dio.put<Map<String, dynamic>>(
          '/api/account/update',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => dioResponse<Map<String, dynamic>>({
          'id': 3,
          'username': 'updated',
          'email': 'u@test.dev',
        }, path: '/api/account/update'),
      );

      final result = await repository.updateProfile(
        username: 'updated',
        email: 'u@test.dev',
        bio: 'bio',
        allowNonFriendDms: true,
        avatarBytes: Uint8List.fromList([1, 2, 3]),
        avatarFileName: 'avatar.jpg',
      );

      expect(result.id, 3);
      verify(
        () => dio.put<Map<String, dynamic>>(
          '/api/account/update',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('updatePassword and deleteAccount call expected endpoints', () async {
      when(
        () => dio.put<void>(
          '/api/account/password',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => dioResponse<void>(null, path: '/api/account/password'));
      when(
        () => dio.delete<void>('/api/account/delete'),
      ).thenAnswer((_) async => dioResponse<void>(null, path: '/api/account/delete'));

      await repository.updatePassword(
        currentPassword: 'old',
        newPassword: 'new',
        confirmNewPassword: 'new',
      );
      await repository.deleteAccount();

      verify(
        () => dio.put<void>('/api/account/password', data: any(named: 'data')),
      ).called(1);
      verify(() => dio.delete<void>('/api/account/delete')).called(1);
    });

    test('presence and push token endpoints are called', () async {
      when(
        () => dio.patch<void>(
          '/api/account/presence',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => dioResponse<void>(null, path: '/api/account/presence'));
      when(
        () => dio.post<void>(
          '/api/account/push-token',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => dioResponse<void>(null, path: '/api/account/push-token'));
      when(
        () => dio.delete<void>(
          '/api/account/push-token',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => dioResponse<void>(null, path: '/api/account/push-token'));

      await repository.updatePresenceStatus('online');
      await repository.registerPushToken(token: 'tok', platform: 'android');
      await repository.unregisterPushToken(token: 'tok');

      verify(
        () => dio.patch<void>(
          '/api/account/presence',
          data: any(named: 'data'),
        ),
      ).called(1);
      verify(
        () => dio.post<void>(
          '/api/account/push-token',
          data: any(named: 'data'),
        ),
      ).called(1);
      verify(
        () => dio.delete<void>(
          '/api/account/push-token',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('currentDevicePlatform returns a known value', () {
      final value = AccountRepository.currentDevicePlatform();
      expect(
        value,
        isIn(<String>['android', 'ios', 'macos', 'windows', 'linux', 'fuchsia']),
      );
    });
  });
}
