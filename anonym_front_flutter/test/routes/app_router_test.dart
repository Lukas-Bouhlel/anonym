import 'dart:async';

import 'package:anonym_front_flutter/providers/auth_providers.dart';
import 'package:anonym_front_flutter/routes/app_router.dart';
import 'package:anonym_front_flutter/routes/app_routes.dart';
import 'package:anonym_front_flutter/services/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

String _pathOf(GoRouter router) => router.routeInformationProvider.value.uri.path;

Future<void> _pumpRouter(
  WidgetTester tester, {
  required AuthProvider auth,
  required GoRouter router,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 80));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('buildRouter', () {
    late MockAuthRepository repository;

    setUp(() {
      repository = MockAuthRepository();
      when(() => repository.setSessionExpiredHandler(any())).thenAnswer((_) {});
      when(() => repository.clearLocalSession()).thenAnswer((_) async {});
      when(() => repository.logout()).thenAnswer((_) async {});
    });

    testWidgets('redirects unauthenticated root to /auth', (tester) async {
      when(() => repository.hydrateSession()).thenAnswer((_) async {});
      when(() => repository.me()).thenThrow(Exception('no session'));

      final auth = AuthProvider(repository);
      addTearDown(auth.dispose);
      await tester.pump();

      final router = buildRouter(auth);
      await _pumpRouter(tester, auth: auth, router: router);

      expect(_pathOf(router), AppRoutes.auth);
    });

    testWidgets('redirects unauthenticated private route to /auth', (tester) async {
      when(() => repository.hydrateSession()).thenAnswer((_) async {});
      when(() => repository.me()).thenThrow(Exception('no session'));

      final auth = AuthProvider(repository);
      addTearDown(auth.dispose);
      await tester.pump();

      final router = buildRouter(auth);
      await _pumpRouter(tester, auth: auth, router: router);

      router.go(AppRoutes.profile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      expect(_pathOf(router), AppRoutes.auth);
    });

    testWidgets('normalizes trailing slash for reset password route', (tester) async {
      when(() => repository.hydrateSession()).thenAnswer((_) async {});
      when(() => repository.me()).thenThrow(Exception('no session'));

      final auth = AuthProvider(repository);
      addTearDown(auth.dispose);
      await tester.pump();

      final router = buildRouter(auth);
      await _pumpRouter(tester, auth: auth, router: router);

      router.go('${AppRoutes.resetPassword}/?token=abc');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      expect(_pathOf(router), AppRoutes.resetPassword);
      expect(router.routeInformationProvider.value.uri.queryParameters['token'], 'abc');
    });

    testWidgets('stays on /loading while auth bootstrap is pending', (tester) async {
      final completer = Completer<void>();
      when(() => repository.hydrateSession()).thenAnswer((_) => completer.future);
      when(() => repository.me()).thenThrow(Exception('unused while bootstrapping'));

      final auth = AuthProvider(repository);
      addTearDown(auth.dispose);

      final router = buildRouter(auth);
      await _pumpRouter(tester, auth: auth, router: router);

      expect(_pathOf(router), AppRoutes.loading);
      completer.complete();
    });

    testWidgets('redirects legacy reset path to modern auth reset path', (tester) async {
      when(() => repository.hydrateSession()).thenAnswer((_) async {});
      when(() => repository.me()).thenThrow(Exception('no session'));

      final auth = AuthProvider(repository);
      addTearDown(auth.dispose);
      await tester.pump();

      final router = buildRouter(auth);
      await _pumpRouter(tester, auth: auth, router: router);

      router.go('${AppRoutes.legacyResetPassword}?token=legacy');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      expect(_pathOf(router), AppRoutes.resetPassword);
      expect(
        router.routeInformationProvider.value.uri.queryParameters['token'],
        'legacy',
      );
    });
  });
}
