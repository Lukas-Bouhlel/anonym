import 'package:anonym_front_flutter/models/user_model.dart';
import 'package:anonym_front_flutter/providers/auth_providers.dart';
import 'package:anonym_front_flutter/screens/blocked_users_screen.dart';
import 'package:anonym_front_flutter/screens/faq_screen.dart';
import 'package:anonym_front_flutter/screens/feedback_screen.dart';
import 'package:anonym_front_flutter/screens/support_screen.dart';
import 'package:anonym_front_flutter/services/admin_repository.dart';
import 'package:anonym_front_flutter/services/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'screen_test_harness.dart';

class MockAdminRepository extends Mock implements AdminRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SupportScreen', () {
    testWidgets('validates fields and submits report', (tester) async {
      final admin = MockAdminRepository();
      when(
        () => admin.report(
          email: any(named: 'email'),
          type: any(named: 'type'),
          content: any(named: 'content'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        Provider<AdminRepository>.value(
          value: admin,
          child: const MaterialApp(home: SupportScreen()),
        ),
      );

      await tester.tap(find.text('Envoyer'));
      await tester.pump();
      expect(find.text('Email requis'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'neo@test.dev');
      await tester.enterText(find.byType(TextFormField).at(1), 'Bug');
      await tester.enterText(find.byType(TextFormField).at(2), 'Details');
      await tester.tap(find.text('Envoyer'));
      await tester.pumpAndSettle();

      verify(
        () => admin.report(
          email: 'neo@test.dev',
          type: 'Bug',
          content: 'Details',
        ),
      ).called(1);
    });
  });

  group('FeedbackScreen', () {
    testWidgets('enables submit only when subject and message are filled', (tester) async {
      final authRepository = MockAuthRepository();
      when(
        () => authRepository.setSessionExpiredHandler(any()),
      ).thenAnswer((_) {});
      when(() => authRepository.hydrateSession()).thenAnswer((_) async {});
      when(
        () => authRepository.me(),
      ).thenAnswer((_) async => const UserModel(id: 1, username: 'neo', email: 'neo@test.dev'));
      when(() => authRepository.clearLocalSession()).thenAnswer((_) async {});
      when(() => authRepository.logout()).thenAnswer((_) async {});

      final authProvider = AuthProvider(authRepository);
      addTearDown(authProvider.dispose);
      await tester.pumpAndSettle();
      authProvider.setUser(
        const UserModel(id: 1, username: 'neo', email: 'neo@test.dev'),
      );

      final admin = MockAdminRepository();
      when(
        () => admin.report(
          email: any(named: 'email'),
          type: any(named: 'type'),
          content: any(named: 'content'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            Provider<AdminRepository>.value(value: admin),
          ],
          child: const MaterialApp(home: FeedbackScreen()),
        ),
      );
      await tester.pump();

      FilledButton button() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Envoyer le feedback'),
      );
      expect(button().onPressed, isNull);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Sujet test');
      await tester.pump();
      expect(button().onPressed, isNull);

      await tester.enterText(fields.at(1), 'Message test');
      await tester.pump();
      expect(button().onPressed, isNotNull);
    });
  });

  group('FaqScreen', () {
    testWidgets('renders and handles accordion interaction', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: FaqScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Comment signaler un probleme ?'), findsOneWidget);
      await tester.tap(find.text('Comment signaler un probleme ?'));
      await tester.pumpAndSettle();
      expect(find.byType(FaqScreen), findsOneWidget);
    });
  });

  group('BlockedUsersScreen', () {
    testWidgets('renders blocked users list from provider', (tester) async {
      final harness = await ScreenTestHarness.create(
        blockedUsers: const [
          UserModel(id: 9, username: 'blocked_user', email: 'b@test.dev'),
        ],
      );
      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.wrapWithProviders(const BlockedUsersScreen()));
      await tester.pumpAndSettle();

      expect(find.text('blocked_user'), findsOneWidget);
    });
  });
}
