import 'package:anonym_front_flutter/models/friend_model.dart';
import 'package:anonym_front_flutter/models/user_model.dart';
import 'package:anonym_front_flutter/screens/friends_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screen_test_harness.dart';

void main() {
  group('FriendsScreen', () {
    testWidgets('affiche les amis actifs et masque les inactifs', (
      WidgetTester tester,
    ) async {
      final harness = await ScreenTestHarness.create(
        friends: const [
          FriendModel(
            id: 1,
            userId: 10,
            friendId: 11,
            status: 'ACTIVE',
            friendDetails: UserModel(
              id: 11,
              username: 'AliceActive',
              email: 'alice@example.test',
            ),
          ),
          FriendModel(
            id: 2,
            userId: 10,
            friendId: 12,
            status: 'BLOCKED',
            friendDetails: UserModel(
              id: 12,
              username: 'BobBlocked',
              email: 'bob@example.test',
            ),
          ),
        ],
      );
      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.wrapWithProviders(const FriendsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Chercher'), findsOneWidget);
      expect(find.text('Amis'), findsWidgets);
      expect(find.text('AliceActive'), findsOneWidget);
      expect(find.text('BobBlocked'), findsNothing);
    });

    testWidgets('bascule vers le filtre Reçues et affiche les demandes', (
      WidgetTester tester,
    ) async {
      final harness = await ScreenTestHarness.create(
        incomingRequests: const [
          FriendModel(
            id: 21,
            userId: 99,
            friendId: 10,
            status: 'PENDING',
            friendDetails: UserModel(
              id: 99,
              username: 'IncomingNeo',
              email: 'neo@example.test',
            ),
          ),
        ],
      );
      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.wrapWithProviders(const FriendsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('IncomingNeo'), findsNothing);

      await tester.tap(find.text('Reçues').first);
      await tester.pumpAndSettle();

      expect(find.text('Demandes reçues'), findsOneWidget);
      expect(find.text('IncomingNeo'), findsOneWidget);
    });
  });
}
