part of 'app_providers.dart';

class _SocialDomainService {
  _SocialDomainService(this._app);

  final AppProvider _app;

  Future<FriendModel?> addFriendByUsername(
    String username, {
    int? userId,
  }) async {
    final normalizedUsername = username.trim();
    if (normalizedUsername.isEmpty) return null;
    if (_app.isFriendRequestPending(
      userId: userId,
      username: normalizedUsername,
    )) {
      _app._errorMessage = 'Demande deja en attente pour cet utilisateur.';
      _app._notifyStateChanged();
      return null;
    }

    _app._isSubmitting = true;
    _app._errorMessage = null;
    _app._notifyStateChanged();
    try {
      final created = await _app._friendsRepository.addByUsername(
        normalizedUsername,
      );
      await Future.wait([
        _app.refreshFriends(silent: true),
        _app.refreshFriendRequests(silent: true),
        _app.refreshBlockedUsers(silent: true),
      ]);
      return created;
    } catch (e) {
      _app._errorMessage = ApiErrorParser.parse(
        e,
        fallback: 'Ajout d\'ami impossible',
      );
      await Future.wait([
        _app.refreshFriendRequests(silent: true),
        _app.refreshBlockedUsers(silent: true),
      ]);
      return null;
    } finally {
      _app._isSubmitting = false;
      _app._notifyStateChanged();
    }
  }

  Future<void> respondToIncomingFriendRequest({
    required int requestId,
    required String status,
  }) async {
    await _app._wrap(() async {
      await _app._friendsRepository.respondToRequest(
        requestId: requestId,
        status: status,
      );
      await Future.wait([
        _app.refreshFriends(silent: true),
        _app.refreshFriendRequests(silent: true),
        _app.refreshBlockedUsers(silent: true),
      ]);
    }, fallbackMessage: 'Impossible de repondre a la demande');
  }

  Future<void> cancelOutgoingFriendRequest(int requestId) async {
    await _app._wrap(() async {
      await _app._friendsRepository.cancelOutgoingRequest(requestId);
      await _app.refreshFriendRequests(silent: true);
    }, fallbackMessage: 'Impossible d\'annuler la demande');
  }

  Future<void> unblockUser(int userId) async {
    await _app._wrap(() async {
      await _app._friendsRepository.unblockUserById(userId);
      await Future.wait([
        _app.refreshFriends(silent: true),
        _app.refreshBlockedUsers(silent: true),
        _app.refreshFriendRequests(silent: true),
      ]);
    }, fallbackMessage: 'Impossible de debloquer cet utilisateur');
  }

  Future<void> blockUser(int userId) async {
    await _app._wrap(() async {
      await _app._friendsRepository.blockUserById(userId);
      await Future.wait([
        _app.refreshFriends(silent: true),
        _app.refreshBlockedUsers(silent: true),
        _app.refreshFriendRequests(silent: true),
      ]);
    }, fallbackMessage: 'Impossible de bloquer cet utilisateur');
  }

  Future<void> deleteFriend(int friendId) async {
    await _app._wrap(() async {
      await _app._friendsRepository.deleteById(friendId);
      _app._friends = await _app._friendsRepository.readAll();
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
    await _app._wrap(() async {
      final created = await _app._channelRepository.create(
        channelType: channelType,
        name: name,
        description: description,
        visibility: visibility,
        memberIds: memberIds,
        imageFilePath: imageFilePath,
      );
      await _app.refreshChannels(silent: true);
      final channelToOpen = _app._channels.firstWhere(
        (channel) => channel.channelId == created.channelId,
        orElse: () => created,
      );
      await _app._channelsDomainService.selectChannel(channelToOpen);
    }, fallbackMessage: 'Creation de channel impossible');
  }

  Future<void> createGroupChannel({
    required String name,
    String description = '',
    required String visibility,
    String? imageFilePath,
  }) {
    return createChannel(
      name: name,
      description: description,
      channelType: 'GROUP',
      visibility: visibility,
      imageFilePath: imageFilePath,
    );
  }

  Future<void> createPrivateDm({required int targetUserId}) async {
    await _app._wrap(() async {
      final created = await _app._channelRepository.create(
        channelType: 'PRIVATE_DM',
        memberIds: [targetUserId],
      );
      await _app.refreshChannels(silent: true);
      final channelToOpen = _app._channels.firstWhere(
        (channel) => channel.channelId == created.channelId,
        orElse: () => created,
      );
      await _app._channelsDomainService.selectChannel(channelToOpen);
    }, fallbackMessage: 'Creation de conversation privee impossible');
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
    final senderId = _app._authProvider.user?.id;
    await _app._wrap(() async {
      final resolvedAvatarUrl = (profileAvatarUrl?.trim().isNotEmpty ?? false)
          ? profileAvatarUrl!.trim()
          : resolveSharedProfileAvatarUrl(profileUserId);
      final resolvedFrameUrl = (profileFrameUrl?.trim().isNotEmpty ?? false)
          ? profileFrameUrl!.trim()
          : resolveSharedProfileFrameUrl(profileUserId);
      final payload = ProfileSharePayloadCodec.encode(
        ProfileSharePayload(
          userId: profileUserId,
          username: normalizedName,
          avatarUrl: resolvedAvatarUrl,
          frameUrl: resolvedFrameUrl,
        ),
      );
      for (final targetUserId in uniqueTargetUserIds) {
        final dm = await _app._channelRepository.create(
          channelType: 'PRIVATE_DM',
          memberIds: [targetUserId],
        );
        if (dm.channelId <= 0) continue;
        if (_app._socketService.isConnected &&
            senderId != null &&
            senderId > 0) {
          _app._socketService.sendPrivateMessage(
            senderId: senderId,
            content: payload,
            channelId: dm.channelId,
          );
        } else {
          await _app._privateMessageRepository.sendWithImage(
            channelId: dm.channelId,
            content: payload,
          );
        }
        sentCount++;
      }
      if (sentCount > 0) {
        await _app.refreshChannels(silent: true);
      }
    }, fallbackMessage: 'Partage du profil impossible');
    return sentCount;
  }

  String? resolveSharedProfileAvatarUrl(int userId) {
    if (userId <= 0) return null;
    final me = _app._authProvider.user;
    if (me != null && me.id == userId) {
      final avatar = me.avatar?.trim();
      if (avatar != null && avatar.isNotEmpty) return avatar;
    }
    final fromAllUsers = _app.userById(userId);
    final avatar = fromAllUsers?.avatar?.trim();
    if (avatar != null && avatar.isNotEmpty) return avatar;
    return null;
  }

  String? resolveSharedProfileFrameUrl(int userId) {
    if (userId <= 0) return null;
    final me = _app._authProvider.user;
    if (me != null && me.id == userId) {
      final frame = _activeFrameUrlFromUser(me);
      if (frame != null && frame.isNotEmpty) return frame;
    }
    final fromAllUsers = _app.userById(userId);
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

class _ChannelsDomainService {
  _ChannelsDomainService(this._app);

  final AppProvider _app;

  Future<void> selectChannel(ChannelModel channel) async {
    final userId = _app._authProvider.user?.id;
    if (userId == null) return;
    final previousChannelId = _app._selectedChannel?.channelId;
    if (previousChannelId != null && previousChannelId != channel.channelId) {
      _app._socketService.leaveChannel(
        channelId: previousChannelId,
        userId: userId,
      );
    }
    _app._selectedChannel = channel;
    _app._isLoadingMessages = true;
    _app._errorMessage = null;
    _app._notifyStateChanged();
    try {
      _app._socketService.joinChannel(
        channelId: channel.channelId,
        userId: userId,
      );
      final responses = await Future.wait([
        _app._channelRepository.readChannelMessages(channel.channelId),
        _app._channelRepository.readChannelUsers(channel.channelId),
      ]);
      _app._messages = responses[0] as List<ChannelMessageModel>;
      _app._channelMembers = responses[1] as List<UserModel>;
      await _app.refreshChannels(silent: true);
    } catch (e) {
      _app._errorMessage = ApiErrorParser.parse(
        e,
        fallback: 'Impossible de charger la conversation',
      );
    } finally {
      _app._isLoadingMessages = false;
      _app._notifyStateChanged();
    }
  }

  Future<void> sendMessage(String content) async {
    final selected = _app._selectedChannel;
    final userId = _app._authProvider.user?.id;
    final normalized = content.trim();
    if (selected == null || userId == null || normalized.isEmpty) return;
    _app._messageError = null;
    if (_app._socketService.isConnected) {
      _app._socketService.sendPrivateMessage(
        senderId: userId,
        content: normalized,
        channelId: selected.channelId,
      );
      _app._scheduleRealtimeMessageDerivedRefreshes();
      _app._notifyStateChanged();
      return;
    }

    await _app._recoverSocketSession(
      reason: 'send_message_socket_disconnected',
    );
    if (_app._socketService.isConnected) {
      _app._socketService.sendPrivateMessage(
        senderId: userId,
        content: normalized,
        channelId: selected.channelId,
      );
      _app._scheduleRealtimeMessageDerivedRefreshes();
      _app._notifyStateChanged();
      return;
    }

    try {
      final message = await _app._privateMessageRepository.sendWithImage(
        channelId: selected.channelId,
        content: normalized,
      );
      final alreadyExists = _app._messages.any(
        (m) => m.messageId == message.messageId,
      );
      if (!alreadyExists) {
        _app._messages = [..._app._messages, message];
      }
      _app._scheduleRealtimeMessageDerivedRefreshes();
      _app._notifyStateChanged();
    } catch (e) {
      _app._messageError = ApiErrorParser.parse(
        e,
        fallback: 'Envoi du message impossible',
      );
      _app._notifyStateChanged();
    }
  }

  Future<void> sendMessageWithImage({
    required String? imagePath,
    List<int>? imageBytes,
    String? imageFileName,
    String content = '',
  }) async {
    final selected = _app._selectedChannel;
    final userId = _app._authProvider.user?.id;
    if (selected == null || userId == null) return;
    if ((imagePath == null || imagePath.isEmpty) && imageBytes == null) return;

    _app._messageError = null;
    _app._notifyStateChanged();

    try {
      final message = await _app._privateMessageRepository.sendWithImage(
        channelId: selected.channelId,
        content: content,
        imageFilePath: imagePath,
        imageBytes: imageBytes,
        imageFileName: imageFileName,
      );
      final alreadyExists = _app._messages.any(
        (m) => m.messageId == message.messageId,
      );
      if (!alreadyExists) {
        _app._messages = [..._app._messages, message];
        _app._notifyStateChanged();
      }
      _app._scheduleRealtimeMessageDerivedRefreshes();
    } catch (e) {
      _app._messageError = ApiErrorParser.parse(
        e,
        fallback: 'Envoi de l\'image impossible',
      );
      _app._notifyStateChanged();
    }
  }

  Future<void> updateMessage({
    required int messageId,
    required String content,
  }) async {
    await _app._wrap(() async {
      final updated = await _app._privateMessageRepository.update(
        messageId: messageId,
        content: content,
      );
      _app._messages = _app._messages
          .map((message) {
            if (message.messageId == messageId) return updated;
            return message;
          })
          .toList(growable: false);
    }, fallbackMessage: 'Modification du message impossible');
  }

  Future<void> deleteMessage(int messageId) async {
    await _app._wrap(() async {
      await _app._privateMessageRepository.delete(messageId);
      _app._messages = _app._messages
          .where((message) => message.messageId != messageId)
          .toList(growable: false);
    }, fallbackMessage: 'Suppression du message impossible');
  }

  Future<void> inviteUsersToSelectedChannel(List<int> userIds) async {
    final selected = _app._selectedChannel;
    if (selected == null) return;
    if (selected.channelType.trim().toUpperCase() == 'PRIVATE_DM') {
      _app._errorMessage = 'Invitation impossible sur une conversation privee.';
      _app._notifyStateChanged();
      return;
    }
    await _app._wrap(() async {
      for (final userId in userIds) {
        await _app._channelRepository.invite(
          channelId: selected.channelId,
          userId: userId,
        );
      }
      _app._channelMembers = await _app._channelRepository.readChannelUsers(
        selected.channelId,
      );
      await _app.refreshChannels(silent: true);
    }, fallbackMessage: 'Invitation impossible');
  }

  Future<void> removeMemberFromSelectedChannel(int userId) async {
    final selected = _app._selectedChannel;
    final currentUserId = _app._authProvider.user?.id;
    if (selected == null || currentUserId == null) return;

    if (selected.channelType.trim().toUpperCase() == 'PRIVATE_DM') {
      _app._errorMessage = 'Action indisponible sur une conversation privee.';
      _app._notifyStateChanged();
      return;
    }

    if (selected.createdBy != currentUserId) {
      _app._errorMessage = 'Seul l\'hote du groupe peut exclure un membre.';
      _app._notifyStateChanged();
      return;
    }

    if (userId == currentUserId) {
      _app._errorMessage = 'L\'hote ne peut pas s\'exclure lui-meme.';
      _app._notifyStateChanged();
      return;
    }

    await _app._wrap(() async {
      await _app._channelRepository.removeMember(
        channelId: selected.channelId,
        userId: userId,
      );
      _app._channelMembers = await _app._channelRepository.readChannelUsers(
        selected.channelId,
      );
      await _app.refreshChannels(silent: true);
    }, fallbackMessage: 'Impossible d\'exclure ce membre');
  }

  Future<void> leaveSelectedChannel() async {
    final selected = _app._selectedChannel;
    final userId = _app._authProvider.user?.id;
    if (selected == null || userId == null) return;
    if (selected.channelType.trim().toUpperCase() == 'PRIVATE_DM') {
      _app._errorMessage = 'Impossible de quitter une conversation privee.';
      _app._notifyStateChanged();
      return;
    }
    await _app._wrap(() async {
      await _app._channelRepository.leaveChannel(selected.channelId);
      _app._socketService.leaveChannel(
        channelId: selected.channelId,
        userId: userId,
      );
      _app._selectedChannel = null;
      _app._messages = const [];
      _app._channelMembers = const [];
      await _app.refreshChannels(silent: true);
    }, fallbackMessage: 'Impossible de quitter le channel');
  }

  Future<void> deleteSelectedChannel() async {
    final selected = _app._selectedChannel;
    if (selected == null) return;
    await _app._wrap(() async {
      await _app._channelRepository.deleteChannel(selected.channelId);
      _app._selectedChannel = null;
      _app._messages = const [];
      _app._channelMembers = const [];
      await _app.refreshChannels(silent: true);
    }, fallbackMessage: 'Suppression du channel impossible');
  }

  Future<void> joinPublicChannel(
    int channelId, {
    String publicFilter = 'all',
  }) async {
    await _app._wrap(() async {
      await _app._channelRepository.joinPublic(channelId);
      await Future.wait([
        _app.refreshChannels(silent: true),
        _app.refreshPublicChannels(filter: publicFilter, silent: true),
      ]);
    }, fallbackMessage: 'Impossible de rejoindre ce channel public');
  }

  Future<void> joinByInviteCode(String code) async {
    await _app._wrap(() async {
      final joinedChannelId = await _app._channelRepository.joinByInvite(code);
      await _app.refreshChannels(silent: true);
      final channelToOpen = _app._channels.firstWhere(
        (channel) => channel.channelId == joinedChannelId,
      );
      await _app._channelsDomainService.selectChannel(channelToOpen);
    }, fallbackMessage: 'Invitation invalide ou expiree');
  }

  Future<Map<String, dynamic>?> createInviteLinkForSelectedChannel({
    required String mode,
    int? expiresInMinutes,
  }) async {
    final selected = _app._selectedChannel;
    if (selected == null) return null;
    try {
      return await _app._channelRepository.createInviteLink(
        channelId: selected.channelId,
        mode: mode,
        expiresInMinutes: expiresInMinutes,
      );
    } catch (e) {
      _app._errorMessage = ApiErrorParser.parse(
        e,
        fallback: 'Creation du lien d\'invitation impossible',
      );
      _app._notifyStateChanged();
      return null;
    }
  }

  Future<void> updateSelectedChannelCover(String imageFilePath) async {
    final selected = _app._selectedChannel;
    if (selected == null) return;
    await _app._wrap(() async {
      await _app._channelRepository.updateCover(
        channelId: selected.channelId,
        imageFilePath: imageFilePath,
      );
      await Future.wait([
        _app.refreshChannels(silent: true),
        _app.refreshPublicChannels(
          filter: _app._lastPublicChannelsFilter,
          silent: true,
        ),
      ]);
      final refreshed = _app._channels.where(
        (channel) => channel.channelId == selected.channelId,
      );
      if (refreshed.isNotEmpty) {
        _app._selectedChannel = refreshed.first;
      }
    }, fallbackMessage: 'Mise a jour de la couverture impossible');
  }

  Future<void> updateSelectedGroup({
    String? name,
    String? description,
    String? visibility,
    String? imageFilePath,
  }) async {
    final selected = _app._selectedChannel;
    if (selected == null) return;
    await _app._wrap(() async {
      final normalizedName = name?.trim();
      final normalizedDescription = description?.trim();
      final normalizedVisibility = visibility?.trim().toUpperCase();

      _app._selectedChannel = selected.copyWith(
        name: normalizedName ?? selected.name,
        description: normalizedDescription ?? selected.description,
        visibility: normalizedVisibility ?? selected.visibility,
      );
      _app._channels = _app._channels
          .map(
            (channel) => channel.channelId == selected.channelId
                ? channel.copyWith(
                    name: normalizedName ?? channel.name,
                    description: normalizedDescription ?? channel.description,
                    visibility: normalizedVisibility ?? channel.visibility,
                  )
                : channel,
          )
          .toList(growable: false);
      _app._notifyStateChanged();

      if (normalizedName != null ||
          normalizedDescription != null ||
          normalizedVisibility != null) {
        await _app._channelRepository.updateGroup(
          channelId: selected.channelId,
          name: normalizedName,
          description: normalizedDescription,
          visibility: normalizedVisibility,
        );
      }

      if (imageFilePath != null && imageFilePath.trim().isNotEmpty) {
        await _app._channelRepository.updateCover(
          channelId: selected.channelId,
          imageFilePath: imageFilePath,
        );
      }

      await Future.wait([
        _app.refreshChannels(silent: true),
        _app.refreshPublicChannels(
          filter: _app._lastPublicChannelsFilter,
          silent: true,
        ),
      ]);
      final refreshed = _app._channels.where(
        (channel) => channel.channelId == selected.channelId,
      );
      if (refreshed.isNotEmpty) {
        _app._selectedChannel = refreshed.first;
      }
    }, fallbackMessage: 'Mise a jour du groupe impossible');
  }

  void closeSelectedChannelView() {
    _app._selectedChannel = null;
    _app._messages = const [];
    _app._channelMembers = const [];
    _app._notifyStateChanged();
  }
}

class _AccountDomainService {
  _AccountDomainService(this._app);

  final AppProvider _app;

  Future<String?> startCheckout(int articleId) async {
    try {
      final url = await _app._paymentRepository.createCheckout(articleId);
      if (url.isEmpty) throw Exception('URL de paiement vide');
      return url;
    } catch (e) {
      _app._errorMessage = ApiErrorParser.parse(
        e,
        fallback: 'Paiement impossible',
      );
      _app._notifyStateChanged();
      return null;
    }
  }

  Future<PaymentConfirmationModel?> confirmPayment(String sessionId) async {
    try {
      final confirmation = await _app._paymentRepository.confirm(sessionId);
      await Future.wait([
        _app.refreshInventory(silent: true),
        _app.refreshInvoices(silent: true),
        _app._refreshCurrentUser(),
      ]);
      _app._notifyStateChanged();
      return confirmation;
    } catch (e) {
      _app._errorMessage = ApiErrorParser.parse(
        e,
        fallback: 'Confirmation du paiement impossible',
      );
      _app._notifyStateChanged();
      return null;
    }
  }

  Future<void> activateInventoryItem(int itemId, bool active) async {
    await _app._wrap(() async {
      await _app._inventoryRepository.updateStatus(
        itemId: itemId,
        active: active,
      );
      _app._inventoryItems = await _app._inventoryRepository.readAll();
      await _app._refreshCurrentUser();
    }, fallbackMessage: 'Activation impossible');
  }

  Future<String?> sendInvoiceByEmail(int invoiceId) async {
    try {
      return await _app._invoiceRepository.sendInvoiceByEmail(invoiceId);
    } catch (e) {
      _app._errorMessage = ApiErrorParser.parse(
        e,
        fallback: 'Envoi de la facture impossible',
      );
      _app._notifyStateChanged();
      return null;
    }
  }

  Future<void> updateProfile({
    required String username,
    required String email,
    String? bio,
    bool? allowNonFriendDms,
    String? avatarFilePath,
    Uint8List? avatarBytes,
    String? avatarFileName,
    bool deleteAvatar = false,
  }) async {
    await _app._wrap(() async {
      final updated = await _app._accountRepository.updateProfile(
        username: username,
        email: email,
        bio: bio,
        allowNonFriendDms: allowNonFriendDms,
        avatarFilePath: avatarFilePath,
        avatarBytes: avatarBytes,
        avatarFileName: avatarFileName,
        deleteAvatar: deleteAvatar,
      );
      _app._authProvider.setUser(updated);
    }, fallbackMessage: 'Mise a jour du profil impossible');
  }

  Future<void> updateMyPresenceStatus(String presenceStatus) async {
    await _app._wrap(() async {
      final normalized = PresenceUtils.normalize(presenceStatus);
      await _app._accountRepository.updatePresenceStatus(normalized);
      final me = _app._authProvider.user;
      if (me == null) return;
      _app._presenceByUserId[me.id] = normalized;
      _app._markPresenceStateChanged();
      if (normalized == PresenceUtils.dnd ||
          normalized == PresenceUtils.invisible) {
        _app._manualPresenceOverride = normalized;
      } else {
        _app._manualPresenceOverride = null;
      }
      _app._authProvider.setUser(me.copyWith(presenceStatus: normalized));
    }, fallbackMessage: 'Mise a jour du statut impossible');
  }

  Future<bool> openChannelById(int channelId) async {
    if (channelId <= 0) return false;
    ChannelModel? target;
    for (final channel in _app._channels) {
      if (channel.channelId == channelId) {
        target = channel;
        break;
      }
    }
    if (target == null) {
      await _app.refreshChannels(silent: true);
      for (final channel in _app._channels) {
        if (channel.channelId == channelId) {
          target = channel;
          break;
        }
      }
    }
    if (target == null) {
      _app._errorMessage = 'Conversation introuvable.';
      _app._notifyStateChanged();
      return false;
    }
    await _app._channelsDomainService.selectChannel(target);
    return _app._selectedChannel?.channelId == channelId;
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    await _app._wrap(() async {
      await _app._accountRepository.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmNewPassword: confirmNewPassword,
      );
    }, fallbackMessage: 'Mise a jour du mot de passe impossible');
  }

  Future<void> deleteAccount() async {
    await _app._wrap(() async {
      await _app._accountRepository.deleteAccount();
      await _app._authProvider.logout();
    }, fallbackMessage: 'Suppression du compte impossible');
  }

  void clearError() {
    _app._errorMessage = null;
    _app._notifyStateChanged();
  }

  void clearMessageError() {
    if (_app._messageError == null) return;
    _app._messageError = null;
    _app._notifyStateChanged();
  }

  void markAllNotificationsAsRead() {
    if (_app._notifications.isEmpty) return;
    var didChange = false;
    final nextReadIds = <String>{..._app._readNotificationIds};
    final next = _app._notifications
        .map((item) {
          nextReadIds.add(item.id);
          if (item.isRead) return item;
          didChange = true;
          return item.copyWith(isRead: true);
        })
        .toList(growable: false);
    if (!didChange && nextReadIds.length == _app._readNotificationIds.length) {
      return;
    }
    _app._notifications = next;
    _app._readNotificationIds = nextReadIds;
    _app._persistReadNotificationIds();
    _app._notifyStateChanged();
  }
}
