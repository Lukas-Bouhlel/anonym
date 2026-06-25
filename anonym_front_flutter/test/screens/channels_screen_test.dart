import 'package:anonym_front_flutter/models/channel_model.dart';
import 'package:anonym_front_flutter/screens/channels_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'screen_test_harness.dart';

void main() {
  group('ChannelsScreen', () {
    testWidgets('affiche les conversations chargees', (
      WidgetTester tester,
    ) async {
      final harness = await ScreenTestHarness.create(
        joinedChannels: const [
          ChannelModel(
            channelId: 100,
            name: 'General Squad',
            description: 'Salon principal',
            createdBy: 1,
          ),
        ],
      );
      addTearDown(harness.dispose);

      await harness.seedJoinedChannels();
      await tester.pumpWidget(
        harness.wrapWithProviders(const ChannelsScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Conversations'), findsOneWidget);
      expect(find.text('General Squad'), findsOneWidget);
      verify(
        () => harness.channelRepository.readUserChannels(filter: 'joined'),
      ).called(greaterThanOrEqualTo(1));
    });

    testWidgets('filtre la liste avec la barre de recherche', (
      WidgetTester tester,
    ) async {
      final harness = await ScreenTestHarness.create(
        joinedChannels: const [
          ChannelModel(
            channelId: 100,
            name: 'General Squad',
            description: 'Salon principal',
            createdBy: 1,
          ),
          ChannelModel(
            channelId: 101,
            name: 'Gaming',
            description: 'Jeux et vocal',
            createdBy: 1,
          ),
        ],
      );
      addTearDown(harness.dispose);

      await harness.seedJoinedChannels();
      await tester.pumpWidget(
        harness.wrapWithProviders(const ChannelsScreen()),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'gaming');
      await tester.pumpAndSettle();

      expect(find.text('Gaming'), findsOneWidget);
      expect(find.text('General Squad'), findsNothing);
    });
  });
}
