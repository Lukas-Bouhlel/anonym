import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Flutter project smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Anonym Flutter'))),
      ),
    );

    expect(find.text('Anonym Flutter'), findsOneWidget);
  });
}
