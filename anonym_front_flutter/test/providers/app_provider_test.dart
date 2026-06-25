import 'package:anonym_front_flutter/models/channel_model.dart';
import 'package:anonym_front_flutter/models/friend_model.dart';
import 'package:anonym_front_flutter/models/inventory_item_model.dart';
import 'package:anonym_front_flutter/models/user_model.dart';
import 'package:anonym_front_flutter/providers/app_providers.dart';
import 'package:anonym_front_flutter/utils/presence_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../screens/screen_test_harness.dart';

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 30));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppProvider (extensions)', () {
    test('discoverableUsers excludes me/friends/requests/blocked users', () async {
      const me = UserModel(id: 1, username: 'me', email: 'me@test.dev');
      const friendUser = UserModel(id: 2, username: 'friend', email: 'f@test.dev');
      const outgoingUser = UserModel(id: 3, username: 'out', email: 'o@test.dev');
      const incomingUser = UserModel(id: 4, username: 'in', email: 'i@test.dev');
      const blockedUser = UserModel(id: 5, username: 'blocked', email: 'b@test.dev');
      const discoverUser = UserModel(id: 6, username: 'new', email: 'n@test.dev');

      final harness = await ScreenTestHarness.create(
        currentAccountUser: me,
        friends: const [
          FriendModel(id: 10, userId: 1, friendId: 2, status: 'ACTIVE', friendDetails: friendUser),
        ],
        incomingRequests: const [
          FriendModel(id: 11, userId: 4, friendId: 1, status: 'PENDING', friendDetails: incomingUser),
        ],
        outgoingRequests: const [
          FriendModel(id: 12, userId: 1, friendId: 3, status: 'PENDING', friendDetails: outgoingUser),
        ],
        blockedUsers: const [blockedUser],
        users: const [me, friendUser, outgoingUser, incomingUser, blockedUser, discoverUser],
      );
      addTearDown(harness.dispose);

      harness.authProvider.setUser(me);
      await _settle();
      await Future.wait([
        harness.appProvider.refreshFriends(silent: true),
        harness.appProvider.refreshFriendRequests(silent: true),
        harness.appProvider.refreshBlockedUsers(silent: true),
        harness.appProvider.refreshUsers(silent: true),
      ]);

      final ids = harness.appProvider.discoverableUsers.map((u) => u.id).toList();
      expect(ids, [6]);
    });

    test('loadJoinDirectoryChannels handles joined/discover filters', () async {
      final joined = [
        const ChannelModel(
          channelId: 1,
          name: 'dm',
          createdBy: 1,
          channelType: 'PRIVATE_DM',
        ),
        const ChannelModel(
          channelId: 2,
          name: 'group',
          createdBy: 1,
          channelType: 'GROUP',
          visibility: 'PUBLIC',
        ),
      ];
      final discover = List<ChannelModel>.generate(
        12,
        (i) => ChannelModel(
          channelId: 100 + i,
          name: 'g$i',
          createdBy: i,
          channelType: i == 0 ? 'PRIVATE_DM' : 'GROUP',
          visibility: 'PUBLIC',
          reputationScore: 200 - i,
        ),
      );

      final harness = await ScreenTestHarness.create(
        joinedChannels: joined,
        publicChannels: discover,
      );
      addTearDown(harness.dispose);

      final joinedFiltered = await harness.appProvider.loadJoinDirectoryChannels(
        filter: 'joined',
      );
      expect(
        joinedFiltered.every((c) => c.channelType.toUpperCase() != 'PRIVATE_DM'),
        isTrue,
      );

      final discoverFiltered = await harness.appProvider.loadJoinDirectoryChannels(
        filter: 'discover',
      );
      expect(discoverFiltered.length, 10);
      expect(discoverFiltered.first.reputationScore, greaterThanOrEqualTo(discoverFiltered.last.reputationScore ?? 0));
      expect(discoverFiltered.every((c) => c.channelType.toUpperCase() == 'GROUP'), isTrue);
    });

    test('startCheckout returns url and openChannelById fails when missing', () async {
      final harness = await ScreenTestHarness.create();
      addTearDown(harness.dispose);

      final checkout = await harness.appProvider.startCheckout(42);
      expect(checkout, 'https://checkout.test');

      final opened = await harness.appProvider.openChannelById(9999);
      expect(opened, isFalse);
      expect(harness.appProvider.errorMessage, isNotNull);
    });

    test('closeSelectedChannelView clears selected channel and messages', () async {
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
      addTearDown(harness.dispose);

      harness.authProvider.setUser(me);
      await _settle();
      await harness.appProvider.refreshChannels(silent: true);
      await harness.appProvider.selectChannel(channel);
      expect(harness.appProvider.selectedChannel?.channelId, 5);

      harness.appProvider.closeSelectedChannelView();
      expect(harness.appProvider.selectedChannel, isNull);
      expect(harness.appProvider.messages, isEmpty);
      expect(harness.appProvider.channelMembers, isEmpty);
    });

    test('addFriendByUsername blocks duplicate pending request', () async {
      const me = UserModel(id: 1, username: 'me', email: 'me@test.dev');
      const target = UserModel(id: 9, username: 'Alice', email: 'a@test.dev');
      final harness = await ScreenTestHarness.create(
        currentAccountUser: me,
        outgoingRequests: const [
          FriendModel(
            id: 22,
            userId: 1,
            friendId: 9,
            status: 'PENDING',
            friendDetails: target,
          ),
        ],
      );
      addTearDown(harness.dispose);

      harness.authProvider.setUser(me);
      await _settle();
      await harness.appProvider.refreshFriendRequests(silent: true);

      final created = await harness.appProvider.addFriendByUsername('Alice', userId: 9);
      expect(created, isNull);
      expect(harness.appProvider.errorMessage, contains('attente'));
    });

    test('publish and stop live location update exposed list', () async {
      const me = UserModel(id: 1, username: 'me', email: 'me@test.dev');
      final harness = await ScreenTestHarness.create(
        currentAccountUser: me,
        friends: const [
          FriendModel(id: 1, userId: 1, friendId: 2, status: 'ACTIVE'),
        ],
      );
      addTearDown(harness.dispose);

      harness.authProvider.setUser(me);
      await _settle();

      harness.appProvider.publishMyLiveLocation(latitude: 48.8566, longitude: 2.3522);
      expect(
        harness.appProvider.liveUserLocations.any((l) => l.userId == 1),
        isTrue,
      );

      harness.appProvider.stopMyLiveLocationSharing();
      expect(
        harness.appProvider.liveUserLocations.any((l) => l.userId == 1),
        isFalse,
      );
    });

    test('didChangeAppLifecycleState updates presence and logout resets state', () async {
      const me = UserModel(
        id: 44,
        username: 'me',
        email: 'me@test.dev',
        presenceStatus: PresenceUtils.online,
      );
      const channel = ChannelModel(
        channelId: 99,
        name: 'group',
        createdBy: 44,
        channelType: 'GROUP',
      );
      final harness = await ScreenTestHarness.create(
        currentAccountUser: me,
        joinedChannels: const [channel],
        users: const [me],
      );
      addTearDown(harness.dispose);

      harness.authProvider.setUser(me);
      await _settle();
      await harness.appProvider.refreshChannels(silent: true);
      expect(harness.appProvider.channels, isNotEmpty);

      await _settle();
      harness.appProvider.didChangeAppLifecycleState(AppLifecycleState.paused);
      await _settle();
      final lifecyclePresence = harness.appProvider.presenceStatusForUser(
        44,
        isCurrentUser: true,
      );
      expect(
        <String>{PresenceUtils.idle, PresenceUtils.online}.contains(
          lifecyclePresence,
        ),
        isTrue,
      );

      await harness.authProvider.logout();
      await _settle();
      expect(harness.appProvider.channels, isEmpty);
      expect(harness.appProvider.notifications, isEmpty);
      expect(harness.appProvider.liveUserLocations, isEmpty);
    });

    test('inventory helpers expose ownership and lookup', () async {
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
      addTearDown(harness.dispose);

      await harness.appProvider.refreshInventory(silent: true);
      expect(harness.appProvider.isArticleOwned(777), isTrue);
      expect(harness.appProvider.inventoryByArticleId(777)?.itemId, 1);
      expect(harness.appProvider.inventoryByArticleId(999), isNull);
    });
  });
}
