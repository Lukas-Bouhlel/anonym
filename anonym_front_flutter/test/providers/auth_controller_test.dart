import 'package:anonym_front_flutter/models/user_model.dart';
import 'package:anonym_front_flutter/providers/auth_providers.dart';
import 'package:anonym_front_flutter/services/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('AuthProvider', () {
    late MockAuthRepository repository;

    setUp(() {
      repository = MockAuthRepository();
      when(() => repository.setSessionExpiredHandler(any())).thenAnswer((_) {});
      when(() => repository.hydrateSession()).thenAnswer((_) async {});
      when(
        () => repository.me(),
      ).thenAnswer((_) async => const UserModel(id: 1, username: 'neo', email: 'neo@test.dev'));
      when(() => repository.clearLocalSession()).thenAnswer((_) async {});
      when(() => repository.logout()).thenAnswer((_) async {});
      when(
        () => repository.login(
          identifier: any(named: 'identifier'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const UserModel(id: 2, username: 'a', email: 'a@test.dev'));
      when(
        () => repository.signup(
          username: any(named: 'username'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const UserModel(id: 3, username: 'b', email: 'b@test.dev'));
      when(
        () => repository.requestRegisterCode(
          email: any(named: 'email'),
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => {'message': 'Code envoye'});
      when(
        () => repository.confirmRegister(
          email: any(named: 'email'),
          code: any(named: 'code'),
        ),
      ).thenAnswer((_) async => const UserModel(id: 4, username: 'c', email: 'c@test.dev'));
      when(
        () => repository.requestPasswordReset(email: any(named: 'email')),
      ).thenAnswer((_) async {});
      when(
        () => repository.completePasswordReset(
          token: any(named: 'token'),
          password: any(named: 'password'),
          confirmPassword: any(named: 'confirmPassword'),
        ),
      ).thenAnswer((_) async {});
    });

    test('bootstrap success hydrates current user', () async {
      final controller = AuthProvider(repository);
      addTearDown(controller.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(controller.isBootstrapping, isFalse);
      expect(controller.isLoggedIn, isTrue);
      expect(controller.user?.id, 1);
      expect(controller.errorMessage, isNull);
    });

    test('bootstrap unauthorized clears local session', () async {
      when(() => repository.me()).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/account'),
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/api/account'),
            statusCode: 401,
          ),
        ),
      );

      final controller = AuthProvider(repository);
      addTearDown(controller.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(controller.isLoggedIn, isFalse);
      verify(() => repository.clearLocalSession()).called(greaterThanOrEqualTo(1));
    });

    test('login and signup update state and busy flag', () async {
      final controller = AuthProvider(repository);
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      final loginOk = await controller.login(identifier: 'id', password: 'pwd');
      expect(loginOk, isTrue);
      expect(controller.user?.id, 2);
      expect(controller.isBusy, isFalse);

      final signupOk = await controller.signup(
        username: 'u',
        email: 'u@test.dev',
        password: 'pwd',
      );
      expect(signupOk, isTrue);
      expect(controller.user?.id, 3);
      expect(controller.errorMessage, isNull);
    });

    test('login and signup failures expose parsed error', () async {
      when(
        () => repository.login(
          identifier: any(named: 'identifier'),
          password: any(named: 'password'),
        ),
      ).thenThrow(Exception('boom-login'));
      when(
        () => repository.signup(
          username: any(named: 'username'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(Exception('boom-signup'));

      final controller = AuthProvider(repository);
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(await controller.login(identifier: 'x', password: 'y'), isFalse);
      expect(controller.errorMessage, isNotNull);
      expect(await controller.signup(username: 'x', email: 'x@x', password: 'y'), isFalse);
      expect(controller.errorMessage, isNotNull);
    });

    test('requestRegisterCode stores info and retryAfter on dio failure', () async {
      final controller = AuthProvider(repository);
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      final ok = await controller.requestRegisterCode(
        email: 'e@test.dev',
        username: 'neo',
        password: 'pwd',
      );
      expect(ok, isTrue);
      expect(controller.infoMessage, 'Code envoye');

      when(
        () => repository.requestRegisterCode(
          email: any(named: 'email'),
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/auth/register/request-code'),
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/api/auth/register/request-code'),
            statusCode: 429,
            data: {'retry_after_seconds': 17.8},
          ),
        ),
      );

      final failed = await controller.requestRegisterCode(
        email: 'e@test.dev',
        username: 'neo',
        password: 'pwd',
      );
      expect(failed, isFalse);
      expect(controller.retryAfterSeconds, 17);
      expect(controller.errorMessage, isNotNull);
    });

    test('confirmRegister and password reset flows', () async {
      final controller = AuthProvider(repository);
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(
        await controller.confirmRegister(email: 'a@test.dev', code: '111111'),
        isTrue,
      );
      expect(controller.user?.id, 4);

      expect(
        await controller.requestPasswordReset(email: 'a@test.dev'),
        isTrue,
      );
      expect(
        await controller.completePasswordReset(
          token: 't',
          password: 'p',
          confirmPassword: 'p',
        ),
        isTrue,
      );
    });

    test('reloadCurrentUser setUser logout and clearError mutate state', () async {
      final controller = AuthProvider(repository);
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      controller.setUser(const UserModel(id: 88, username: 'manual', email: 'm@test.dev'));
      expect(controller.user?.id, 88);

      when(
        () => repository.me(),
      ).thenAnswer((_) async => const UserModel(id: 99, username: 'reloaded', email: 'r@test.dev'));
      await controller.reloadCurrentUser();
      expect(controller.user?.id, 99);

      when(() => repository.logout()).thenThrow(Exception('logout fail'));
      await controller.logout();
      expect(controller.user, isNull);
      verify(() => repository.clearLocalSession()).called(greaterThanOrEqualTo(1));

      controller.clearError();
      expect(controller.errorMessage, isNull);
    });

    test('session expired handler resets state', () async {
      void Function()? captured;
      when(() => repository.setSessionExpiredHandler(any())).thenAnswer((invocation) {
        captured = invocation.positionalArguments.first as void Function();
      });

      final controller = AuthProvider(repository);
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);
      controller.setUser(const UserModel(id: 7, username: 'u', email: 'u@test.dev'));

      captured?.call();

      expect(controller.user, isNull);
      expect(controller.isBootstrapping, isFalse);
      expect(controller.errorMessage, isNotNull);
    });
  });
}


