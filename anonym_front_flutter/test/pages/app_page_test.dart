import 'package:anonym_front_flutter/pages/app_page.dart';
import 'package:anonym_front_flutter/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../screens/screen_test_harness.dart';

void main() {
  testWidgets('AnonymApp builds MaterialApp.router with app title', (
    tester,
  ) async {
    final harness = await ScreenTestHarness.create();
    addTearDown(harness.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: harness.authProvider,
        child: const AnonymApp(),
      ),
    );
    await tester.pumpAndSettle();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.title, 'Anonym');
    expect(find.byType(DecoratedBox), findsWidgets);
  });
}

