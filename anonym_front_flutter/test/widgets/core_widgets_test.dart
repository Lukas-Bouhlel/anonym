import 'package:anonym_front_flutter/widgets/anonym_map/anonym_map_data.dart';
import 'package:anonym_front_flutter/widgets/app_remote_image.dart';
import 'package:anonym_front_flutter/widgets/centered_form.dart';
import 'package:anonym_front_flutter/widgets/navigation/anonym_back_button.dart';
import 'package:anonym_front_flutter/widgets/presence_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CenteredForm', () {
    testWidgets('applies max width and padding', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CenteredForm(
              child: Text('form-body'),
            ),
          ),
        ),
      );

      final constrainedFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ConstrainedBox &&
            widget.constraints.maxWidth == 420,
      );
      expect(constrainedFinder, findsOneWidget);
      final constrained = tester.widget<ConstrainedBox>(constrainedFinder);
      expect(constrained.constraints.maxWidth, 420);
      expect(find.text('form-body'), findsOneWidget);
      expect(find.byType(Padding), findsWidgets);
    });
  });

  group('PresenceBadge', () {
    testWidgets('renders online and offline colors', (tester) async {
      Widget buildBadge(String? status, {required bool isCurrentUser}) {
        return MaterialApp(
          home: Scaffold(
            body: PresenceBadge(
              presenceStatus: status,
              isCurrentUser: isCurrentUser,
              size: 12,
            ),
          ),
        );
      }

      await tester.pumpWidget(buildBadge('online', isCurrentUser: false));
      Container onlineContainer = tester.widget<Container>(find.byType(Container));
      BoxDecoration onlineDecoration = onlineContainer.decoration! as BoxDecoration;
      expect(onlineDecoration.color, const Color(0xFF97F6C1));

      await tester.pumpWidget(buildBadge('unknown-status', isCurrentUser: false));
      Container offlineContainer = tester.widget<Container>(find.byType(Container));
      BoxDecoration offlineDecoration =
          offlineContainer.decoration! as BoxDecoration;
      expect(offlineDecoration.color, const Color(0xFF9AA4C1));
    });
  });

  group('AppRemoteImage', () {
    testWidgets('shows fallback icon when url is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppRemoteImage(
              url: null,
              width: 32,
              height: 32,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.image_not_supported), findsOneWidget);
    });

    testWidgets('supports custom fallback icon without network call', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppRemoteImage(
              url: null,
              width: 32,
              height: 32,
              fallbackIcon: Icons.person_off,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.person_off), findsOneWidget);
    });
  });

  group('AnonymBackButton', () {
    testWidgets('invokes custom onTap callback', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnonymBackButton(
              onTap: () => tapped++,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AnonymBackButton));
      await tester.pump();
      expect(tapped, 1);
    });
  });

  test('AnonymMapCameraTarget serializes to JSON map', () {
    const target = AnonymMapCameraTarget(
      latitude: 48.8566,
      longitude: 2.3522,
      zoom: 15,
      revision: 3,
    );

    expect(target.toJson(), {
      'latitude': 48.8566,
      'longitude': 2.3522,
      'zoom': 15.0,
      'revision': 3,
    });
  });
}
