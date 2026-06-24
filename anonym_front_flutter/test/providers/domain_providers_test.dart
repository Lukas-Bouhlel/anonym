import 'package:anonym_front_flutter/models/channel_model.dart';
import 'package:anonym_front_flutter/models/friend_model.dart';
import 'package:anonym_front_flutter/models/inventory_item_model.dart';
import 'package:anonym_front_flutter/models/user_model.dart';
import 'package:anonym_front_flutter/providers/app_orchestrator_provider.dart';
import 'package:anonym_front_flutter/providers/channels_provider.dart';
import 'package:anonym_front_flutter/providers/commerce_provider.dart';
import 'package:anonym_front_flutter/providers/notifications_provider.dart';
import 'package:anonym_front_flutter/providers/presence_provider.dart';
import 'package:anonym_front_flutter/providers/social_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../screens/screen_test_harness.dart';

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 30));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Domain providers', () {
    test(
      'SocialProvider exposes discoverable users and pending requests',
      () async {
        const me = UserModel(id: 1, username: 'me', email: 'me@test.dev');
        const friendUser = UserModel(
          id: 2,
          username: 'friend',
          email: 'f@test.dev',
        );
        const outgoingUser = UserModel(
          id: 3,
          username: 'out',
          email: 'o@test.dev',
        );
        const discoverUser = UserModel(
          id: 6,
          username: 'new',
          email: 'n@test.dev',
        );

        final harness = await ScreenTestHarness.create(
          currentAccountUser: me,
          friends: const [
            FriendModel(
              id: 10,
              userId: 1,
              friendId: 2,
              status: 'ACTIVE',
              friendDetails: friendUser,
            ),
          ],
          outgoingRequests: const [
            FriendModel(
              id: 12,
              userId: 1,
              friendId: 3,
              status: 'PENDING',
              friendDetails: outgoingUser,
            ),
          ],
          users: const [me, friendUser, outgoingUser, discoverUser],
        );
        final social = SocialProvider(harness.appProvider);
        addTearDown(() async {
          social.dispose();
          await harness.dispose();
        });

        harness.authProvider.setUser(me);
        await _settle();
        await Future.wait([
          social.refreshFriends(silent: true),
          social.refreshFriendRequests(silent: true),
          social.refreshUsers(silent: true),
        ]);

        expect(social.isFriendRequestPending(userId: 3), isTrue);
        expect(social.discoverableUsers.map((u) => u.id).toList(), [6]);
      },
    );

    test('ChannelsProvider can select and close a channel view', () async {
      const me = UserModel(id: 7, username: 'neo', email: 'neo@test.dev');
      const channel = ChannelModel(
        channelId: 5,
        name: 'general',
        createdBy: 7,
        channelType: 'GROUP',
      );
      final harness = await ScreenTestHarness.create(
        currentAccountUser: me,
        joinedChannels: const [channel],
      );
      final channels = ChannelsProvider(harness.appProvider);
      addTearDown(() async {
        channels.dispose();
        await harness.dispose();
      });

      harness.authProvider.setUser(me);
      await _settle();
      await channels.refreshChannels(silent: true);
      await channels.selectChannel(channel);
      expect(channels.selectedChannel?.channelId, 5);

      channels.closeSelectedChannelView();
      expect(channels.selectedChannel, isNull);
      expect(channels.messages, isEmpty);
      expect(channels.channelMembers, isEmpty);
    });

    test(
      'PresenceProvider publishes and stops live location sharing',
      () async {
        const me = UserModel(id: 1, username: 'me', email: 'me@test.dev');
        final harness = await ScreenTestHarness.create(currentAccountUser: me);
        final presence = PresenceProvider(harness.appProvider);
        addTearDown(() async {
          presence.dispose();
          await harness.dispose();
        });

        harness.authProvider.setUser(me);
        await _settle();

        presence.publishMyLiveLocation(latitude: 48.8566, longitude: 2.3522);
        expect(
          presence.liveUserLocations.any((item) => item.userId == 1),
          isTrue,
        );

        presence.stopMyLiveLocationSharing();
        expect(
          presence.liveUserLocations.any((item) => item.userId == 1),
          isFalse,
        );
      },
    );

    test('CommerceProvider exposes ownership helpers', () async {
      final harness = await ScreenTestHarness.create(
        inventoryItems: const [
          InventoryItemModel(
            itemId: 1,
            userId: 1,
            articleId: 777,
            active: true,
          ),
        ],
      );
      final commerce = CommerceProvider(harness.appProvider);
      addTearDown(() async {
        commerce.dispose();
        await harness.dispose();
      });

      await commerce.refreshInventory(silent: true);
      expect(commerce.isArticleOwned(777), isTrue);
      expect(commerce.inventoryByArticleId(777)?.itemId, 1);
      expect(commerce.inventoryByArticleId(999), isNull);
    });

    test('Domain providers notify only for scoped domain changes', () async {
      const channel = ChannelModel(
        channelId: 100,
        name: 'scope-check',
        createdBy: 1,
        channelType: 'GROUP',
      );
      final harness = await ScreenTestHarness.create(
        joinedChannels: const [channel],
      );
      final social = SocialProvider(harness.appProvider);
      final channels = ChannelsProvider(harness.appProvider);
      final commerce = CommerceProvider(harness.appProvider);
      addTearDown(() async {
        commerce.dispose();
        channels.dispose();
        social.dispose();
        await harness.dispose();
      });

      var socialNotifications = 0;
      var channelsNotifications = 0;
      var commerceNotifications = 0;

      social.addListener(() => socialNotifications++);
      channels.addListener(() => channelsNotifications++);
      commerce.addListener(() => commerceNotifications++);

      await channels.refreshChannels(silent: true);

      expect(channelsNotifications, greaterThan(0));
      expect(socialNotifications, 0);
      expect(commerceNotifications, 0);
    });

    test(
      'Orchestrator and notifications providers proxy app-level actions',
      () async {
        const me = UserModel(id: 13, username: 'iris', email: 'i@test.dev');
        final harness = await ScreenTestHarness.create(currentAccountUser: me);
        final orchestrator = AppOrchestratorProvider(harness.appProvider);
        final notifications = NotificationsProvider(harness.appProvider);
        addTearDown(() async {
          notifications.dispose();
          orchestrator.dispose();
          await harness.dispose();
        });

        harness.authProvider.setUser(me);
        await _settle();
        await orchestrator.refreshAll();
        notifications.markAllNotificationsAsRead();

        expect(orchestrator.errorMessage, isNull);
        expect(notifications.unreadNotificationsCount, 0);
      },
    );
  });
}
