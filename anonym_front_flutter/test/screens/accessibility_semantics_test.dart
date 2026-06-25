import 'package:anonym_front_flutter/models/channel_model.dart';
import 'package:anonym_front_flutter/models/user_model.dart';
import 'package:anonym_front_flutter/screens/channels_screen.dart';
import 'package:anonym_front_flutter/screens/login_screen.dart';
import 'package:anonym_front_flutter/screens/register_screen.dart';
import 'package:anonym_front_flutter/widgets/navigation/anonym_glass_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screen_test_harness.dart';

void main() {
  group('Mobile accessibility semantics', () {
    testWidgets('login exposes accessible form labels and actions', (
      WidgetTester tester,
    ) async {
      final harness = await ScreenTestHarness.create();
      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.wrapWithProviders(const LoginScreen()));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.bySemanticsLabel(RegExp('E-mail ou pseudo')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Mot de passe')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Connexion')), findsWidgets);
      expect(find.byTooltip('Afficher le mot de passe'), findsOneWidget);
    });

    testWidgets('registration exposes accessible fields and consent state', (
      WidgetTester tester,
    ) async {
      final harness = await ScreenTestHarness.create();
      addTearDown(harness.dispose);

      await tester.pumpWidget(
        harness.wrapWithProviders(const RegisterScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.bySemanticsLabel(RegExp('E-mail')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Pseudo')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Mot de passe')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Confirmation')), findsWidgets);
      expect(
        find.bySemanticsLabel(
          RegExp('Accepter les conditions generales'),
          skipOffstage: false,
        ),
        findsWidgets,
      );
      expect(
        find.bySemanticsLabel(RegExp('Regles du mot de passe')),
        findsWidgets,
      );
    });

    testWidgets('main navigation exposes French accessible tab labels', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AnonymGlassBottomNav(
              currentIndex: 1,
              onTap: (_) {},
              onCenterTap: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.bySemanticsLabel(RegExp('Accueil')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Messages')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Recherche')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Profil')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Creer')), findsWidgets);
    });

    testWidgets('messages screen exposes accessible chat actions', (
      WidgetTester tester,
    ) async {
      final harness = await ScreenTestHarness.create(
        currentAccountUser: const UserModel(
          id: 1,
          username: 'MobileTester',
          email: 'mobile@example.test',
        ),
        joinedChannels: const [
          ChannelModel(
            channelId: 100,
            name: 'General Squad',
            description: 'Salon principal',
            createdBy: 1,
          ),
        ],
      );
      harness.authProvider.setUser(
        const UserModel(
          id: 1,
          username: 'MobileTester',
          email: 'mobile@example.test',
        ),
      );

      await harness.seedJoinedChannels();
      await tester.pumpWidget(
        harness.wrapWithProviders(const ChannelsScreen()),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('General Squad'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Nouvelle conversation')),
        findsWidgets,
      );

      await tester.tap(find.text('General Squad').first);
      await tester.pump(const Duration(seconds: 1));

      expect(find.bySemanticsLabel(RegExp('Ajouter une image')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Message')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Envoyer le message')), findsWidgets);

      await tester.pump(const Duration(milliseconds: 100));
      await harness.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
