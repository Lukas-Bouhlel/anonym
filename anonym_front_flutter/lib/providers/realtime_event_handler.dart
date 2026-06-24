part of 'app_providers.dart';

class AppProviderRealtimeEventHandler {
  AppProviderRealtimeEventHandler(this._app);

  final AppProvider _app;

  void onNewMessageFromSocket(ChannelMessageModel message) {
    if (_app._shouldStoreInAppNotifications) {
      _app._pushNewMessageNotification(message);
    }
    scheduleRealtimeMessageDerivedRefreshes();
    final incomingChannelId = message.channelId;
    if (_app._selectedChannel == null) {
      unawaited(_app.refreshChannels(silent: true));
      return;
    }
    if (incomingChannelId <= 0 ||
        incomingChannelId != _app._selectedChannel!.channelId) {
      unawaited(_app.refreshChannels(silent: true));
      return;
    }
    if (message.messageId > 0 &&
        _app._messages.any(
          (existing) => existing.messageId == message.messageId,
        )) {
      unawaited(_app.refreshChannels(silent: true));
      return;
    }
    final enriched = ChannelMessageModel(
      messageId: message.messageId,
      content: message.content,
      channelId: incomingChannelId,
      senderId: message.senderId,
      status: message.status,
      createdAt: message.createdAt,
      sender: message.sender,
      imageUrl: message.imageUrl,
    );
    _app._messages = [..._app._messages, enriched];
    _app._notifyStateChanged();
    unawaited(_app.refreshChannels(silent: true));
  }

  void onMessageUpdatedFromSocket(ChannelMessageModel message) {
    final incomingChannelId = message.channelId;
    if (message.messageId <= 0) return;
    if (_app._selectedChannel == null ||
        incomingChannelId != _app._selectedChannel!.channelId) {
      unawaited(_app.refreshChannels(silent: true));
      return;
    }

    var didChange = false;
    _app._messages = _app._messages
        .map((existing) {
          if (existing.messageId != message.messageId) return existing;
          didChange = true;
          return ChannelMessageModel(
            messageId: message.messageId,
            content: message.content,
            channelId: incomingChannelId,
            senderId: message.senderId ?? existing.senderId,
            status: message.status ?? existing.status,
            createdAt: message.createdAt ?? existing.createdAt,
            sender: message.sender ?? existing.sender,
            imageUrl: message.imageUrl ?? existing.imageUrl,
          );
        })
        .toList(growable: false);
    if (didChange) {
      _app._notifyStateChanged();
    }
    unawaited(_app.refreshChannels(silent: true));
  }

  void onMessageDeletedFromSocket(Map<String, dynamic> payload) {
    final messageId = _app._toInt(payload['messageId'] ?? payload['message_id']);
    final channelId = _app._toInt(payload['channelId'] ?? payload['channel_id']);
    if (messageId <= 0) return;
    if (_app._selectedChannel == null ||
        (channelId > 0 && channelId != _app._selectedChannel!.channelId)) {
      unawaited(_app.refreshChannels(silent: true));
      return;
    }

    final before = _app._messages.length;
    _app._messages = _app._messages
        .where((message) => message.messageId != messageId)
        .toList(growable: false);
    if (_app._messages.length != before) {
      _app._notifyStateChanged();
    }
    unawaited(_app.refreshChannels(silent: true));
  }

  void onFriendRequestReceivedFromSocket(Map<String, dynamic> payload) {
    _app._rtLog('onFriendRequestReceived payload=$payload');
    final senderRaw = payload['sender'];
    final sender = senderRaw is Map<String, dynamic>
        ? senderRaw
        : senderRaw is Map
        ? Map<String, dynamic>.from(senderRaw)
        : const <String, dynamic>{};
    final senderId = _app._toInt(
      sender['id'] ?? sender['userId'] ?? sender['user_id'],
    );
    final meId = _app._authProvider.user?.id;
    if (meId != null && senderId == meId) return;
    final username = (sender['username'] ?? 'Utilisateur').toString().trim();
    final createdAt = _app._parseDate(
      payload['createdAt'] ?? payload['created_at'] ?? payload['date'],
    );
    final requestId = _app._toInt(
      payload['requestId'] ?? payload['request_id'],
    );
    if (_app._shouldStoreInAppNotifications) {
      _app._prependNotification(
        AppNotificationModel(
          id: 'fr-$requestId-${createdAt.microsecondsSinceEpoch}',
          type: AppNotificationType.friendRequest,
          title: "Vous avez reçu une demande d'ami de $username",
          subtitle: _app._formatNotificationTime(createdAt),
          createdAt: createdAt,
          avatarUrl: sender['avatar']?.toString(),
          relatedUserId: senderId > 0 ? senderId : null,
        ),
      );
    }
    _upsertIncomingRequestFromSocket(
      payload: payload,
      sender: sender,
      senderId: senderId,
      meId: meId,
    );
    scheduleSocialStateRefresh(delay: const Duration(milliseconds: 180));
  }

  void onFriendRequestRespondedFromSocket(Map<String, dynamic> payload) {
    _app._rtLog('onFriendRequestResponded payload=$payload');
    scheduleSocialStateRefresh();
  }

  void onFriendRequestSentFromSocket(Map<String, dynamic> payload) {
    _app._rtLog('onFriendRequestSent payload=$payload');
    scheduleSocialStateRefresh();
  }

  void onFriendRequestCancelledFromSocket(Map<String, dynamic> payload) {
    _app._rtLog('onFriendRequestCancelled payload=$payload');
    scheduleSocialStateRefresh();
  }

  void onFriendshipBlockedFromSocket(Map<String, dynamic> payload) {
    _app._rtLog('onFriendshipBlocked payload=$payload');
    scheduleSocialStateRefresh();
    unawaited(_app.refreshChannels(silent: true));
  }

  void onFriendshipUnblockedFromSocket(Map<String, dynamic> payload) {
    _app._rtLog('onFriendshipUnblocked payload=$payload');
    scheduleSocialStateRefresh();
  }

  void onFriendshipDeletedFromSocket(Map<String, dynamic> payload) {
    _app._rtLog('onFriendshipDeleted payload=$payload');
    scheduleSocialStateRefresh();
    unawaited(_app.refreshChannels(silent: true));
  }

  void onFriendsStateUpdatedFromSocket(Map<String, dynamic> payload) {
    _app._rtLog('onFriendsStateUpdated payload=$payload');
    scheduleSocialStateRefresh();
    unawaited(_app.refreshChannels(silent: true));
  }

  void onChannelInvitedFromSocket(Map<String, dynamic> payload) {
    scheduleRealtimeChannelsRefresh();
    if (!_app._shouldStoreInAppNotifications) return;
    final now = DateTime.now();
    final channelName = (payload['channelName'] ?? payload['name'] ?? 'groupe')
        .toString()
        .trim();
    final channelId = _app._toInt(
      payload['channelId'] ?? payload['channel_id'],
    );
    _app._prependNotification(
      AppNotificationModel(
        id: 'channel-invite-${channelId > 0 ? channelId : now.microsecondsSinceEpoch}',
        type: AppNotificationType.newMessage,
        title: 'Invitation reçue',
        subtitle: channelName.isEmpty ? 'Nouveau groupe' : channelName,
        createdAt: now,
        relatedChannelId: channelId > 0 ? channelId : null,
      ),
    );
  }

  void onChannelMemberRemovedFromSocket(Map<String, dynamic> payload) {
    final channelId = _app._toInt(
      payload['channelId'] ?? payload['channel_id'],
    );
    final removedUserId = _app._toInt(
      payload['removedUserId'] ?? payload['removed_user_id'],
    );
    final currentUserId = _app._authProvider.user?.id;
    scheduleRealtimeChannelsRefresh();
    final selected = _app._selectedChannel;
    if (selected == null || selected.channelId != channelId) return;
    if (currentUserId != null && removedUserId == currentUserId) {
      _app._selectedChannel = null;
      _app._messages = const [];
      _app._channelMembers = const [];
      _app._notifyStateChanged();
      return;
    }
    unawaited(() async {
      try {
        _app._channelMembers = await _app._channelRepository.readChannelUsers(
          channelId,
        );
        _app._notifyStateChanged();
      } catch (_) {}
    }());
  }

  void onChannelUpdatedFromSocket(Map<String, dynamic> payload) {
    _app._rtLog('onChannelUpdated payload=$payload');
    scheduleRealtimeChannelsRefresh();
  }

  void onMessageErrorFromSocket(String message) {
    final normalized = message.trim().toLowerCase();
    if (normalized.isEmpty ||
        normalized.contains('friend') ||
        normalized.contains('ami')) {
      _app._messageError =
          'DM impossible: vous devez etre ami actif ou activer les DM non-amis.';
    } else {
      _app._messageError = 'Envoi du message impossible.';
    }
    _app._notifyStateChanged();
  }

  void onLocationSnapshotFromSocket(List<dynamic> payload) {
    final meId = _app._authProvider.user?.id;
    final next = <int, LiveUserLocationModel>{};
    for (final entry in payload) {
      if (entry is! Map) continue;
      final model = LiveUserLocationModel.fromJson(
        Map<String, dynamic>.from(entry),
      );
      if (!_app._isLocationPayloadValid(model)) continue;
      if (!_app._shouldDisplayLocationForUser(model.userId)) continue;
      next[model.userId] = model;
    }
    if (meId != null && _app._liveLocationsByUserId.containsKey(meId)) {
      next[meId] = _app._liveLocationsByUserId[meId]!;
    }
    _app._liveLocationsByUserId
      ..clear()
      ..addAll(next);
    _app._markPresenceStateChanged();
    _app._notifyStateChanged();
  }

  void onLocationUpdateFromSocket(Map<String, dynamic> payload) {
    final model = LiveUserLocationModel.fromJson(payload);
    if (!_app._isLocationPayloadValid(model)) return;
    if (!_app._shouldDisplayLocationForUser(model.userId)) return;
    _app._liveLocationsByUserId[model.userId] = model;
    _app._markPresenceStateChanged();
    _app._notifyStateChanged();
  }

  void onLocationRemoveFromSocket(int userId) {
    if (!_app._liveLocationsByUserId.containsKey(userId)) return;
    _app._liveLocationsByUserId.remove(userId);
    _app._markPresenceStateChanged();
    _app._notifyStateChanged();
  }

  void onPresenceUpdatedFromSocket(Map<String, dynamic> payload) {
    final rawUserId = payload['userId'] ?? payload['user_id'] ?? payload['id'];
    final rawStatus = payload['presence_status'] ?? payload['presenceStatus'];
    int userId = 0;
    if (rawUserId is int) {
      userId = rawUserId;
    } else if (rawUserId is num) {
      userId = rawUserId.toInt();
    } else if (rawUserId is String) {
      userId = int.tryParse(rawUserId) ?? 0;
    }
    if (userId <= 0) return;
    final normalized = PresenceUtils.normalize(rawStatus?.toString());
    _app._presenceByUserId[userId] = normalized;
    _app._markPresenceStateChanged();
    final me = _app._authProvider.user;
    if (me != null && me.id == userId) {
      _app._authProvider.setUser(me.copyWith(presenceStatus: normalized));
      return;
    }
    _app._notifyStateChanged();
  }

  void scheduleRealtimeMessageDerivedRefreshes() {
    scheduleRealtimeChannelsRefresh();
    scheduleRealtimeProfileStatsRefresh();
  }

  void scheduleRealtimeChannelsRefresh({
    Duration delay = const Duration(milliseconds: 260),
  }) {
    _app._realtimeChannelsRefreshDebounce?.cancel();
    _app._realtimeChannelsRefreshDebounce = Timer(delay, () {
      unawaited(_runRealtimeChannelsRefresh());
    });
  }

  void scheduleRealtimeProfileStatsRefresh({
    Duration delay = const Duration(milliseconds: 700),
  }) {
    _app._realtimeProfileStatsRefreshDebounce?.cancel();
    _app._realtimeProfileStatsRefreshDebounce = Timer(delay, () {
      unawaited(_runRealtimeProfileStatsRefresh());
    });
  }

  void scheduleSocialStateRefresh({Duration delay = Duration.zero}) {
    _app._socialRefreshDebounce?.cancel();
    _app._socialRefreshDebounce = Timer(delay, () {
      unawaited(_runSocialStateRefresh());
    });
  }

  Future<void> _runRealtimeChannelsRefresh() async {
    if (_app._isRefreshingRealtimeChannels) {
      _app._hasQueuedRealtimeChannelsRefresh = true;
      return;
    }
    _app._isRefreshingRealtimeChannels = true;
    try {
      await Future.wait([
        _app.refreshChannels(silent: true),
        _app.refreshPublicChannels(
          filter: _app._lastPublicChannelsFilter,
          silent: true,
        ),
      ]);
    } catch (_) {
    } finally {
      _app._isRefreshingRealtimeChannels = false;
      if (_app._hasQueuedRealtimeChannelsRefresh) {
        _app._hasQueuedRealtimeChannelsRefresh = false;
        unawaited(_runRealtimeChannelsRefresh());
      }
    }
  }

  Future<void> _runRealtimeProfileStatsRefresh() async {
    if (_app._isRefreshingRealtimeProfileStats) {
      _app._hasQueuedRealtimeProfileStatsRefresh = true;
      return;
    }
    _app._isRefreshingRealtimeProfileStats = true;
    try {
      await _app._refreshCurrentUser();
      _app._realtimeStatsVersion++;
      _app._notifyStateChanged();
    } catch (_) {
    } finally {
      _app._isRefreshingRealtimeProfileStats = false;
      if (_app._hasQueuedRealtimeProfileStatsRefresh) {
        _app._hasQueuedRealtimeProfileStatsRefresh = false;
        unawaited(_runRealtimeProfileStatsRefresh());
      }
    }
  }

  Future<void> _runSocialStateRefresh() async {
    if (_app._isRefreshingSocialState) {
      _app._hasQueuedSocialRefresh = true;
      return;
    }
    _app._isRefreshingSocialState = true;
    try {
      await Future.wait([
        _app.refreshFriends(silent: true),
        _app.refreshFriendRequests(silent: true),
        _app.refreshBlockedUsers(silent: true),
        _app.refreshUsers(silent: true),
      ]);
      final removedHiddenLocations = _app._pruneHiddenLiveLocations();
      _app._socketService.requestLiveLocationsSnapshot();
      if (removedHiddenLocations) {
        _app._notifyStateChanged();
      }
    } finally {
      _app._isRefreshingSocialState = false;
      if (_app._hasQueuedSocialRefresh) {
        _app._hasQueuedSocialRefresh = false;
        unawaited(_runSocialStateRefresh());
      }
    }
  }

  void _upsertIncomingRequestFromSocket({
    required Map<String, dynamic> payload,
    required Map<String, dynamic> sender,
    required int senderId,
    required int? meId,
  }) {
    if (senderId <= 0 || meId == null || meId <= 0) return;
    final requestId = _app._toInt(
      payload['requestId'] ?? payload['request_id'],
    );
    if (requestId <= 0) return;
    final senderUser = UserModel.fromJson(<String, dynamic>{
      'id': senderId,
      'username': sender['username'] ?? 'Utilisateur',
      'email': sender['email'] ?? '',
      'avatar': sender['avatar'],
      'bio': sender['bio'],
      'presence_status': sender['presence_status'] ?? sender['presenceStatus'],
    });
    final incoming = FriendModel(
      id: requestId,
      userId: senderId,
      friendId: meId,
      status: 'PENDING',
      friendDetails: senderUser,
    );
    final existingIndex = _app._incomingFriendRequests.indexWhere(
      (request) =>
          request.id == requestId ||
          (request.userId == senderId &&
              request.status.trim().toUpperCase() == 'PENDING'),
    );
    if (existingIndex >= 0) {
      final updated = [..._app._incomingFriendRequests];
      updated[existingIndex] = incoming;
      _app._incomingFriendRequests = updated;
    } else {
      _app._incomingFriendRequests = [
        incoming,
        ..._app._incomingFriendRequests,
      ];
    }
    _app._presenceByUserId[senderId] = PresenceUtils.normalize(
      senderUser.presenceStatus,
    );
    _app._markPresenceStateChanged();
    _app._notifyStateChanged();
  }
}
