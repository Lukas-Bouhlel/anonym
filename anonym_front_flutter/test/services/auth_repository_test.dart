import 'package:anonym_front_flutter/services/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'repository_test_utils.dart';

void main() {
  group('AuthRepository', () {
    late MockDio dio;
    late MockApiClient apiClient;
    late AuthRepository repository;

    setUp(() {
      dio = MockDio();
      apiClient = MockApiClient();
      repository = AuthRepository(dio, apiClient);
    });

    test('setSessionExpiredHandler forwards handler to ApiClient', () {
      void handler() {}
      when(() => apiClient.setSessionExpiredHandler(any())).thenReturn(null);

      repository.setSessionExpiredHandler(handler);

      verify(() => apiClient.setSessionExpiredHandler(any())).called(1);
    });

    test('hydrateSession skips refresh when no session cookie is available', () async {
      when(
        () => apiClient.buildSocketAuthHeaders(),
      ).thenAnswer((_) async => const <String, dynamic>{});

      await repository.hydrateSession();

      verify(() => apiClient.buildSocketAuthHeaders()).called(1);
      verifyNever(() => apiClient.refreshSession());
    });

    test('hydrateSession refreshes when a session cookie is available', () async {
      when(() => apiClient.buildSocketAuthHeaders()).thenAnswer(
        (_) async => const <String, dynamic>{'Cookie': 'sid=test-cookie'},
      );
      when(() => apiClient.refreshSession()).thenAnswer((_) async => true);

      await repository.hydrateSession();

      verify(() => apiClient.buildSocketAuthHeaders()).called(1);
      verify(() => apiClient.refreshSession()).called(1);
    });

    test('login parses payload.user when present', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/api/auth/login',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => dioResponse<Map<String, dynamic>>({
          'user': {
            'id': 10,
            'username': 'neo',
            'email': 'neo@test.dev',
          },
        }, path: '/api/auth/login'),
      );

      final result = await repository.login(identifier: 'neo', password: 'pwd');

      expect(result.id, 10);
      expect(result.username, 'neo');
      expect(result.email, 'neo@test.dev');
      final body = verify(
        () => dio.post<Map<String, dynamic>>(
          '/api/auth/login',
          data: captureAny(named: 'data'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(body['identifier'], 'neo');
      expect(body['password'], 'pwd');
    });

    test('signup sends request then logs user in', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/api/auth/signup',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => dioResponse<Map<String, dynamic>>({}, path: '/api/auth/signup'));
      when(
        () => dio.post<Map<String, dynamic>>(
          '/api/auth/login',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => dioResponse<Map<String, dynamic>>({
          'id': 1,
          'username': 'alice',
          'email': 'alice@test.dev',
        }, path: '/api/auth/login'),
      );

      final result = await repository.signup(
        username: 'alice',
        email: 'alice@test.dev',
        password: 'secret',
      );

      expect(result.id, 1);
      verify(
        () => dio.post<Map<String, dynamic>>(
          '/api/auth/signup',
          data: any(named: 'data'),
        ),
      ).called(1);
      verify(
        () => dio.post<Map<String, dynamic>>(
          '/api/auth/login',
          data: any(named: 'data'),
        ),
      ).called(1);
    });

    test('requestRegisterCode validates required fields', () async {
      expect(
        () => repository.requestRegisterCode(
          email: ' ',
          username: 'neo',
          password: 'pwd',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => repository.requestRegisterCode(
          email: 'neo@test.dev',
          username: ' ',
          password: 'pwd',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => repository.requestRegisterCode(
          email: 'neo@test.dev',
          username: 'neo',
          password: ' ',
        ),
        throwsA(isA<ArgumentError>()),
      );
      verifyNever(
        () => dio.post<Map<String, dynamic>>(
          '/api/auth/register/request-code',
          data: any(named: 'data'),
        ),
      );
    });

    test('requestRegisterCode trims and returns response payload', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/api/auth/register/request-code',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => dioResponse<Map<String, dynamic>>({
          'message': 'sent',
        }, path: '/api/auth/register/request-code'),
      );

      final result = await repository.requestRegisterCode(
        email: ' neo@test.dev ',
        username: ' neo ',
        password: ' p ',
      );

      expect(result['message'], 'sent');
      final body = verify(
        () => dio.post<Map<String, dynamic>>(
          '/api/auth/register/request-code',
          data: captureAny(named: 'data'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(body['email'], 'neo@test.dev');
      expect(body['username'], 'neo');
      expect(body['password'], 'p');
    });

    test('confirmRegister parses nested user payload', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/api/auth/register/confirm',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => dioResponse<Map<String, dynamic>>({
          'user': {
            'id': 3,
            'username': 'user3',
            'email': 'u3@test.dev',
          },
        }, path: '/api/auth/register/confirm'),
      );

      final result = await repository.confirmRegister(
        email: 'u3@test.dev',
        code: '123456',
      );

      expect(result.id, 3);
      expect(result.username, 'user3');
    });

    test('requestPasswordReset and completePasswordReset call endpoints', () async {
      when(
        () => dio.post<void>(
          '/api/auth/reset-password',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => dioResponse<void>(null, path: '/api/auth/reset-password'));
      when(
        () => dio.post<void>(
          '/api/auth/reset',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => dioResponse<void>(null, path: '/api/auth/reset'));

      await repository.requestPasswordReset(email: 'a@test.dev');
      await repository.completePasswordReset(
        token: 'token',
        password: 'new',
        confirmPassword: 'new',
      );

      verify(
        () => dio.post<void>('/api/auth/reset-password', data: any(named: 'data')),
      ).called(1);
      verify(() => dio.post<void>('/api/auth/reset', data: any(named: 'data'))).called(1);
    });

    test('me parses account response', () async {
      when(
        () => dio.get<Map<String, dynamic>>('/api/account'),
      ).thenAnswer(
        (_) async => dioResponse<Map<String, dynamic>>({
          'id': 55,
          'username': 'me',
          'email': 'me@test.dev',
        }, path: '/api/account'),
      );

      final me = await repository.me();

      expect(me.id, 55);
      expect(me.username, 'me');
    });

    test('logout always clears local session', () async {
      when(() => dio.post<void>('/api/auth/logout')).thenThrow(
        dioException(path: '/api/auth/logout', statusCode: 500),
      );
      when(() => apiClient.clearSessionData()).thenAnswer((_) async {});

      await expectLater(repository.logout(), throwsA(isA<DioException>()));
      verify(() => apiClient.clearSessionData()).called(1);
    });

    test('clearLocalSession delegates to api client', () async {
      when(() => apiClient.clearSessionData()).thenAnswer((_) async {});

      await repository.clearLocalSession();

      verify(() => apiClient.clearSessionData()).called(1);
    });
  });
}
