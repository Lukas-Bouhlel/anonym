import 'package:anonym_front_flutter/screens/app_shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screen_test_harness.dart';

void main() {
  group('AppShellScreen', () {
    testWidgets('demarre sur un onglet configurable et navigue vers Friends', (
      WidgetTester tester,
    ) async {
      final harness = await ScreenTestHarness.create();
      addTearDown(harness.dispose);

      await tester.pumpWidget(
        harness.wrapWithProviders(
          const AppShellScreen(initialTabIndex: 1),
          withScaffold: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Conversations'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);

      await tester.tap(find.text('Search').first);
      await tester.pumpAndSettle();

      expect(find.text('Chercher'), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('ouvre la feuille des actions rapides', (
      WidgetTester tester,
    ) async {
      final harness = await ScreenTestHarness.create();
      addTearDown(harness.dispose);

      await tester.pumpWidget(
        harness.wrapWithProviders(
          const AppShellScreen(initialTabIndex: 1),
          withScaffold: false,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      expect(find.text('Creer ton groupe'), findsOneWidget);
      expect(find.text('Creer un groupe'), findsOneWidget);
      expect(find.text('Rejoindre un groupe'), findsOneWidget);
    });
  });
}
