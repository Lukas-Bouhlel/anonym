part of 'app_providers.dart';

/// Opérations liées aux conversations, messages et groupes.
extension AppProviderChannelsX on AppProvider {
  Future<void> selectChannel(ChannelModel channel) async {
    final userId = _authProvider.user?.id;
    if (userId == null) return;

    final previousChannelId = _selectedChannel?.channelId;
    if (previousChannelId != null && previousChannelId != channel.channelId) {
      _socketService.leaveChannel(channelId: previousChannelId, userId: userId);
    }

    _selectedChannel = channel;
    _isLoadingMessages = true;
    _errorMessage = null;
    _notifyStateChanged();

    try {
      _socketService.joinChannel(channelId: channel.channelId, userId: userId);
      final responses = await Future.wait([
        _channelRepository.readChannelMessages(channel.channelId),
        _channelRepository.readChannelUsers(channel.channelId),
      ]);
      _messages = responses[0] as List<ChannelMessageModel>;
      _channelMembers = responses[1] as List<UserModel>;
      await refreshChannels(silent: true);
    } catch (e) {
      _errorMessage = ApiErrorParser.parse(
        e,
        fallback: 'Impossible de charger la conversation',
      );
    } finally {
      _isLoadingMessages = false;
      _notifyStateChanged();
    }
  }

  Future<void> sendMessage(String content) async {
    final selected = _selectedChannel;
    final userId = _authProvider.user?.id;
    final normalized = content.trim();
    if (selected == null || userId == null || normalized.isEmpty) return;
    _messageError = null;
    if (_socketService.isConnected) {
      _socketService.sendPrivateMessage(
        senderId: userId,
        content: normalized,
        channelId: selected.channelId,
      );
      _scheduleRealtimeMessageDerivedRefreshes();
      _notifyStateChanged();
      return;
    }

    await _recoverSocketSession(reason: 'send_message_socket_disconnected');
    if (_socketService.isConnected) {
      _socketService.sendPrivateMessage(
        senderId: userId,
        content: normalized,
        channelId: selected.channelId,
      );
      _scheduleRealtimeMessageDerivedRefreshes();
      _notifyStateChanged();
      return;
    }

    try {
      final message = await _privateMessageRepository.sendWithImage(
        channelId: selected.channelId,
        content: normalized,
      );
      final alreadyExists = _messages.any(
        (m) => m.messageId == message.messageId,
      );
      if (!alreadyExists) {
        _messages = [..._messages, message];
      }
      _scheduleRealtimeMessageDerivedRefreshes();
      _notifyStateChanged();
    } catch (e) {
      _messageError = ApiErrorParser.parse(
        e,
        fallback: 'Envoi du message impossible',
      );
      _notifyStateChanged();
    }
  }

  Future<void> sendMessageWithImage({
    required String? imagePath,
    List<int>? imageBytes,
    String? imageFileName,
    String content = '',
  }) async {
    final selected = _selectedChannel;
    final userId = _authProvider.user?.id;
    if (selected == null || userId == null) return;
    if ((imagePath == null || imagePath.isEmpty) && imageBytes == null) return;

    _messageError = null;
    _notifyStateChanged();

    try {
      final message = await _privateMessageRepository.sendWithImage(
        channelId: selected.channelId,
        content: content,
        imageFilePath: imagePath,
        imageBytes: imageBytes,
        imageFileName: imageFileName,
      );
      final alreadyExists = _messages.any(
        (m) => m.messageId == message.messageId,
      );
      if (!alreadyExists) {
        _messages = [..._messages, message];
        _notifyStateChanged();
      }
      _scheduleRealtimeMessageDerivedRefreshes();
    } catch (e) {
      _messageError = ApiErrorParser.parse(
        e,
        fallback: 'Envoi de l\'image impossible',
      );
      _notifyStateChanged();
    }
  }

  Future<void> updateMessage({
    required int messageId,
    required String content,
  }) async {
    await _wrap(() async {
      final updated = await _privateMessageRepository.update(
        messageId: messageId,
        content: content,
      );
      _messages = _messages
          .map((message) {
            if (message.messageId == messageId) return updated;
            return message;
          })
          .toList(growable: false);
    }, fallbackMessage: 'Modification du message impossible');
  }

  Future<void> deleteMessage(int messageId) async {
    await _wrap(() async {
      await _privateMessageRepository.delete(messageId);
      _messages = _messages
          .where((message) => message.messageId != messageId)
          .toList(growable: false);
    }, fallbackMessage: 'Suppression du message impossible');
  }

  Future<void> inviteUsersToSelectedChannel(List<int> userIds) async {
    final selected = _selectedChannel;
    if (selected == null) return;
    if (selected.channelType.trim().toUpperCase() == 'PRIVATE_DM') {
      _errorMessage = 'Invitation impossible sur une conversation privée.';
      _notifyStateChanged();
      return;
    }
    await _wrap(() async {
      for (final userId in userIds) {
        await _channelRepository.invite(
          channelId: selected.channelId,
          userId: userId,
        );
      }
      _channelMembers = await _channelRepository.readChannelUsers(
        selected.channelId,
      );
      await refreshChannels(silent: true);
    }, fallbackMessage: 'Invitation impossible');
  }

  Future<void> removeMemberFromSelectedChannel(int userId) async {
    final selected = _selectedChannel;
    final currentUserId = _authProvider.user?.id;
    if (selected == null || currentUserId == null) return;

    if (selected.channelType.trim().toUpperCase() == 'PRIVATE_DM') {
      _errorMessage = 'Action indisponible sur une conversation privée.';
      _notifyStateChanged();
      return;
    }

    if (selected.createdBy != currentUserId) {
      _errorMessage = 'Seul l\'hôte du groupe peut exclure un membre.';
      _notifyStateChanged();
      return;
    }

    if (userId == currentUserId) {
      _errorMessage = 'L\'hôte ne peut pas s\'exclure lui-même.';
      _notifyStateChanged();
      return;
    }

    await _wrap(() async {
      await _channelRepository.removeMember(
        channelId: selected.channelId,
        userId: userId,
      );
      _channelMembers = await _channelRepository.readChannelUsers(
        selected.channelId,
      );
      await refreshChannels(silent: true);
    }, fallbackMessage: 'Impossible d\'exclure ce membre');
  }

  Future<void> leaveSelectedChannel() async {
    final selected = _selectedChannel;
    final userId = _authProvider.user?.id;
    if (selected == null || userId == null) return;
    if (selected.channelType.trim().toUpperCase() == 'PRIVATE_DM') {
      _errorMessage = 'Impossible de quitter une conversation privée.';
      _notifyStateChanged();
      return;
    }
    await _wrap(() async {
      await _channelRepository.leaveChannel(selected.channelId);
      _socketService.leaveChannel(
        channelId: selected.channelId,
        userId: userId,
      );
      _selectedChannel = null;
      _messages = const [];
      _channelMembers = const [];
      await refreshChannels(silent: true);
    }, fallbackMessage: 'Impossible de quitter le channel');
  }

  Future<void> deleteSelectedChannel() async {
    final selected = _selectedChannel;
    if (selected == null) return;
    await _wrap(() async {
      await _channelRepository.deleteChannel(selected.channelId);
      _selectedChannel = null;
      _messages = const [];
      _channelMembers = const [];
      await refreshChannels(silent: true);
    }, fallbackMessage: 'Suppression du channel impossible');
  }

  Future<void> joinPublicChannel(
    int channelId, {
    String publicFilter = 'all',
  }) async {
    await _wrap(() async {
      await _channelRepository.joinPublic(channelId);
      await Future.wait([
        refreshChannels(silent: true),
        refreshPublicChannels(filter: publicFilter, silent: true),
      ]);
    }, fallbackMessage: 'Impossible de rejoindre ce channel public');
  }

  Future<void> joinByInviteCode(String code) async {
    await _wrap(() async {
      final joinedChannelId = await _channelRepository.joinByInvite(code);
      await refreshChannels(silent: true);
      final channelToOpen = _channels.firstWhere(
        (channel) => channel.channelId == joinedChannelId,
      );
      await selectChannel(channelToOpen);
    }, fallbackMessage: 'Invitation invalide ou expirée');
  }

  Future<Map<String, dynamic>?> createInviteLinkForSelectedChannel({
    required String mode,
    int? expiresInMinutes,
  }) async {
    final selected = _selectedChannel;
    if (selected == null) return null;
    try {
      return await _channelRepository.createInviteLink(
        channelId: selected.channelId,
        mode: mode,
        expiresInMinutes: expiresInMinutes,
      );
    } catch (e) {
      _errorMessage = ApiErrorParser.parse(
        e,
        fallback: 'Création du lien d\'invitation impossible',
      );
      _notifyStateChanged();
      return null;
    }
  }

  Future<void> updateSelectedChannelCover(String imageFilePath) async {
    final selected = _selectedChannel;
    if (selected == null) return;
    await _wrap(() async {
      await _channelRepository.updateCover(
        channelId: selected.channelId,
        imageFilePath: imageFilePath,
      );
      await Future.wait([
        refreshChannels(silent: true),
        refreshPublicChannels(filter: _lastPublicChannelsFilter, silent: true),
      ]);
      final refreshed = _channels.where(
        (channel) => channel.channelId == selected.channelId,
      );
      if (refreshed.isNotEmpty) {
        _selectedChannel = refreshed.first;
      }
    }, fallbackMessage: 'Mise à jour de la couverture impossible');
  }

  Future<void> updateSelectedGroup({
    String? name,
    String? description,
    String? visibility,
    String? imageFilePath,
  }) async {
    final selected = _selectedChannel;
    if (selected == null) return;
    await _wrap(() async {
      final normalizedName = name?.trim();
      final normalizedDescription = description?.trim();
      final normalizedVisibility = visibility?.trim().toUpperCase();

      _selectedChannel = selected.copyWith(
        name: normalizedName ?? selected.name,
        description: normalizedDescription ?? selected.description,
        visibility: normalizedVisibility ?? selected.visibility,
      );
      _channels = _channels
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
      _notifyStateChanged();

      if (normalizedName != null ||
          normalizedDescription != null ||
          normalizedVisibility != null) {
        await _channelRepository.updateGroup(
          channelId: selected.channelId,
          name: normalizedName,
          description: normalizedDescription,
          visibility: normalizedVisibility,
        );
      }

      if (imageFilePath != null && imageFilePath.trim().isNotEmpty) {
        await _channelRepository.updateCover(
          channelId: selected.channelId,
          imageFilePath: imageFilePath,
        );
      }

      await Future.wait([
        refreshChannels(silent: true),
        refreshPublicChannels(filter: _lastPublicChannelsFilter, silent: true),
      ]);
      final refreshed = _channels.where(
        (channel) => channel.channelId == selected.channelId,
      );
      if (refreshed.isNotEmpty) {
        _selectedChannel = refreshed.first;
      }
    }, fallbackMessage: 'Mise à jour du groupe impossible');
  }

  void closeSelectedChannelView() {
    _selectedChannel = null;
    _messages = const [];
    _channelMembers = const [];
    _notifyStateChanged();
  }

}
