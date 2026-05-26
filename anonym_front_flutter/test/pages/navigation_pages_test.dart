import 'package:anonym_front_flutter/models/points_summary_model.dart';
import 'package:anonym_front_flutter/pages/navigation_pages.dart';
import 'package:anonym_front_flutter/services/points_repository.dart';
import 'package:anonym_front_flutter/screens/app_shell_screen.dart';
import 'package:anonym_front_flutter/screens/login_screen.dart';
import 'package:anonym_front_flutter/screens/payment_success_screen.dart';
import 'package:anonym_front_flutter/screens/placeholder_screen.dart';
import 'package:anonym_front_flutter/screens/profile_screen.dart';
import 'package:anonym_front_flutter/screens/public_home_screen.dart';
import 'package:anonym_front_flutter/screens/register_screen.dart';
import 'package:anonym_front_flutter/screens/reset_password_screen.dart';
import 'package:anonym_front_flutter/screens/splash_screen.dart';
import 'package:anonym_front_flutter/screens/support_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../screens/screen_test_harness.dart';

class MockPointsRepository extends Mock implements PointsRepository {}

void main() {
  group('Navigation pages', () {
    late ScreenTestHarness harness;
    late MockPointsRepository pointsRepository;

    setUp(() async {
      harness = await ScreenTestHarness.create();
      pointsRepository = MockPointsRepository();
      when(() => pointsRepository.readMe()).thenAnswer(
        (_) async => PointsSummaryModel.fromJson(const <String, dynamic>{
          'period': 'day',
          'periodSelection': 'auto',
          'range': {'startDate': null, 'endDate': null},
          'user': {
            'id': 1,
            'username': 'neo',
            'totalPoints': 0,
            'level': {
              'level': 1,
              'maxLevel': 10,
              'totalPoints': 0,
              'currentLevelThreshold': 0,
              'nextLevelThreshold': 100,
              'pointsIntoLevel': 0,
              'pointsNeededForNextLevel': 100,
              'pointsRemainingForNextLevel': 100,
              'isMaxLevel': false,
            },
          },
          'totals': {'messagesCount': 0, 'pointsEarned': 0},
          'history': <Object>[],
        }),
      );
    });

    tearDown(() async {
      await harness.dispose();
    });

    Future<void> pumpPage(WidgetTester tester, Widget page) async {
      await tester.pumpWidget(
        Provider<PointsRepository>.value(
          value: pointsRepository,
          child: harness.wrapWithProviders(page),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
    }

    testWidgets('SplashPage builds SplashScreen', (tester) async {
      await pumpPage(tester, const SplashPage());
      expect(find.byType(SplashScreen), findsOneWidget);
    });

    testWidgets('PublicHomePage builds PublicHomeScreen', (tester) async {
      await pumpPage(tester, const PublicHomePage());
      expect(find.byType(PublicHomeScreen), findsOneWidget);
    });

    testWidgets('LoginPage builds LoginScreen', (tester) async {
      await pumpPage(tester, const LoginPage());
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('RegisterPage builds RegisterScreen', (tester) async {
      await pumpPage(tester, const RegisterPage());
      expect(find.byType(RegisterScreen), findsOneWidget);
    });

    testWidgets('ResetPasswordPage forwards token to screen', (tester) async {
      await pumpPage(tester, const ResetPasswordPage(token: 'abc'));
      final screen = tester.widget<ResetPasswordScreen>(
        find.byType(ResetPasswordScreen),
      );
      expect(screen.token, 'abc');
    });

    testWidgets('AppShellPage builds AppShellScreen', (tester) async {
      await pumpPage(tester, const AppShellPage());
      expect(find.byType(AppShellScreen), findsOneWidget);
    });

    testWidgets('PaymentSuccessPage forwards session id', (tester) async {
      await pumpPage(tester, const PaymentSuccessPage(sessionId: null));
      final screen = tester.widget<PaymentSuccessScreen>(
        find.byType(PaymentSuccessScreen),
      );
      expect(screen.sessionId, isNull);
    });

    testWidgets('ProfilePage builds ProfileScreen', (tester) async {
      await pumpPage(tester, const ProfilePage());
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('SupportPage builds SupportScreen', (tester) async {
      await pumpPage(tester, const SupportPage());
      expect(find.byType(SupportScreen), findsOneWidget);
    });

    testWidgets('PlaceholderPage forwards title', (tester) async {
      await pumpPage(tester, const PlaceholderPage(title: 'Admin'));
      final screen = tester.widget<PlaceholderScreen>(
        find.byType(PlaceholderScreen),
      );
      expect(screen.title, 'Admin');
    });
  });
}
