part of 'app_providers.dart';

/// Opérations sociales: amis, blocages, partages de profil.
extension AppProviderSocialX on AppProvider {
  Future<FriendModel?> addFriendByUsername(
    String username, {
    int? userId,
  }) async {
    final normalizedUsername = username.trim();
    if (normalizedUsername.isEmpty) return null;
    if (isFriendRequestPending(userId: userId, username: normalizedUsername)) {
      _errorMessage = 'Demande déjà en attente pour cet utilisateur.';
      _notifyStateChanged();
      return null;
    }

    _isSubmitting = true;
    _errorMessage = null;
    _notifyStateChanged();

    try {
      final created = await _friendsRepository.addByUsername(
        normalizedUsername,
      );
      await Future.wait([
        refreshFriends(silent: true),
        refreshFriendRequests(silent: true),
        refreshBlockedUsers(silent: true),
      ]);
      return created;
    } catch (e) {
      _errorMessage = ApiErrorParser.parse(e, fallback: 'Ajout d\'ami impossible');
      await Future.wait([
        refreshFriendRequests(silent: true),
        refreshBlockedUsers(silent: true),
      ]);
      return null;
    } finally {
      _isSubmitting = false;
      _notifyStateChanged();
    }
  }

  Future<void> respondToIncomingFriendRequest({
    required int requestId,
    required String status,
  }) async {
    await _wrap(() async {
      await _friendsRepository.respondToRequest(
        requestId: requestId,
        status: status,
      );
      await Future.wait([
        refreshFriends(silent: true),
        refreshFriendRequests(silent: true),
        refreshBlockedUsers(silent: true),
      ]);
    }, fallbackMessage: 'Impossible de répondre à la demande');
  }

  Future<void> cancelOutgoingFriendRequest(int requestId) async {
    await _wrap(() async {
      await _friendsRepository.cancelOutgoingRequest(requestId);
      await refreshFriendRequests(silent: true);
    }, fallbackMessage: 'Impossible d\'annuler la demande');
  }

  Future<void> unblockUser(int userId) async {
    await _wrap(() async {
      await _friendsRepository.unblockUserById(userId);
      await Future.wait([
        refreshFriends(silent: true),
        refreshBlockedUsers(silent: true),
        refreshFriendRequests(silent: true),
      ]);
    }, fallbackMessage: 'Impossible de débloquer cet utilisateur');
  }

  Future<void> blockUser(int userId) async {
    await _wrap(() async {
      await _friendsRepository.blockUserById(userId);
      await Future.wait([
        refreshFriends(silent: true),
        refreshBlockedUsers(silent: true),
        refreshFriendRequests(silent: true),
      ]);
    }, fallbackMessage: 'Impossible de bloquer cet utilisateur');
  }

  Future<void> deleteFriend(int friendId) async {
    await _wrap(() async {
      await _friendsRepository.deleteById(friendId);
      _friends = await _friendsRepository.readAll();
    }, fallbackMessage: 'Suppression d\'ami impossible');
  }

  Future<void> createChannel({
    required String name,
    required String description,
    String channelType = 'GROUP',
    String visibility = 'PUBLIC',
    List<int>? memberIds,
    String? imageFilePath,
  }) async {
    await _wrap(() async {
      final created = await _channelRepository.create(
        channelType: channelType,
        name: name,
        description: description,
        visibility: visibility,
        memberIds: memberIds,
        imageFilePath: imageFilePath,
      );
      await refreshChannels(silent: true);
      final channelToOpen = _channels.firstWhere(
        (channel) => channel.channelId == created.channelId,
        orElse: () => created,
      );
      await selectChannel(channelToOpen);
    }, fallbackMessage: 'Création de channel impossible');
  }

  Future<void> createGroupChannel({
    required String name,
    String description = '',
    required String visibility,
    String? imageFilePath,
  }) async {
    await createChannel(
      name: name,
      description: description,
      channelType: 'GROUP',
      visibility: visibility,
      imageFilePath: imageFilePath,
    );
  }

  Future<void> createPrivateDm({required int targetUserId}) async {
    await _wrap(() async {
      final created = await _channelRepository.create(
        channelType: 'PRIVATE_DM',
        memberIds: [targetUserId],
      );
      await refreshChannels(silent: true);
      final channelToOpen = _channels.firstWhere(
        (channel) => channel.channelId == created.channelId,
        orElse: () => created,
      );
      await selectChannel(channelToOpen);
    }, fallbackMessage: 'Création de conversation privée impossible');
  }

  Future<int> shareProfileToUsers({
    required int profileUserId,
    required String profileUsername,
    required List<int> targetUserIds,
    String? profileAvatarUrl,
    String? profileFrameUrl,
  }) async {
    final normalizedName = profileUsername.trim();
    final uniqueTargetUserIds = targetUserIds
        .where((id) => id > 0)
        .toSet()
        .toList(growable: false);
    if (profileUserId <= 0 ||
        normalizedName.isEmpty ||
        uniqueTargetUserIds.isEmpty) {
      return 0;
    }

    var sentCount = 0;
    final senderId = _authProvider.user?.id;
    await _wrap(() async {
      final resolvedAvatarUrl = (profileAvatarUrl?.trim().isNotEmpty ?? false)
          ? profileAvatarUrl!.trim()
          : _resolveSharedProfileAvatarUrl(profileUserId);
      final resolvedFrameUrl = (profileFrameUrl?.trim().isNotEmpty ?? false)
          ? profileFrameUrl!.trim()
          : _resolveSharedProfileFrameUrl(profileUserId);
      final payload = ProfileSharePayloadCodec.encode(
        ProfileSharePayload(
          userId: profileUserId,
          username: normalizedName,
          avatarUrl: resolvedAvatarUrl,
          frameUrl: resolvedFrameUrl,
        ),
      );
      for (final targetUserId in uniqueTargetUserIds) {
        final dm = await _channelRepository.create(
          channelType: 'PRIVATE_DM',
          memberIds: [targetUserId],
        );
        if (dm.channelId <= 0) continue;
        if (_socketService.isConnected && senderId != null && senderId > 0) {
          _socketService.sendPrivateMessage(
            senderId: senderId,
            content: payload,
            channelId: dm.channelId,
          );
        } else {
          await _privateMessageRepository.sendWithImage(
            channelId: dm.channelId,
            content: payload,
          );
        }
        sentCount++;
      }
      if (sentCount > 0) {
        await refreshChannels(silent: true);
      }
    }, fallbackMessage: 'Partage du profil impossible');
    return sentCount;
  }

  String? _resolveSharedProfileAvatarUrl(int userId) {
    if (userId <= 0) return null;
    final me = _authProvider.user;
    if (me != null && me.id == userId) {
      final avatar = me.avatar?.trim();
      if (avatar != null && avatar.isNotEmpty) return avatar;
    }
    final fromAllUsers = userById(userId);
    final avatar = fromAllUsers?.avatar?.trim();
    if (avatar != null && avatar.isNotEmpty) return avatar;
    return null;
  }

  String? _resolveSharedProfileFrameUrl(int userId) {
    if (userId <= 0) return null;
    final me = _authProvider.user;
    if (me != null && me.id == userId) {
      final frame = _activeFrameUrlFromUser(me);
      if (frame != null && frame.isNotEmpty) return frame;
    }
    final fromAllUsers = userById(userId);
    final frame = _activeFrameUrlFromUser(fromAllUsers);
    if (frame != null && frame.isNotEmpty) return frame;
    return null;
  }

  String? _activeFrameUrlFromUser(UserModel? user) {
    if (user == null) return null;
    for (final item in user.inventories) {
      if (!item.active) continue;
      final shop = item.shop;
      if (shop == null) continue;
      final content = shop.content.trim();
      if (content.isEmpty) continue;
      if (shop.type.trim().toUpperCase() == 'CADRE') return content;
    }
    return null;
  }

}
