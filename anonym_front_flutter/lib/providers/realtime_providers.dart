part of 'app_providers.dart';

/// Intégration temps réel: socket, événements entrants et synchronisation.
extension AppProviderRealtimeX on AppProvider {
  void _handleAuthChange() {
    final currentUserId = _authProvider.user?.id;
    if (currentUserId == null) {
      if (_activeUserId != null) {
        _sendInvisibleAndDisconnect();
        _resetState();
      }
      return;
    }
    if (_activeUserId != null && _activeUserId != currentUserId) {
      _rtLog(
        'auth switch oldUser=$_activeUserId newUser=$currentUserId -> reset realtime state',
      );
      // Do not reuse old realtime state/socket when the authenticated user changes.
      _resetState();
    }
    if (_activeUserId == currentUserId) return;
    _activeUserId = currentUserId;
    _bootForLoggedInUser();
  }

  Future<void> _bootForLoggedInUser() async {
    await _connectSocketWithLatestAuth();
    _startSessionKeepAlive();
    await refreshAll();
    await _setupPushNotifications();
    await _applyLifecyclePresence(
      WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed,
    );
  }

  Future<void> _connectSocketWithLatestAuth() async {
    final socketAuthHeaders = await _apiClient.buildSocketAuthHeaders();
    final socketAuthToken = await _apiClient.buildSocketAuthToken();
    _rtLog(
      'boot socket user=${_authProvider.user?.id} hasToken=${socketAuthToken != null && socketAuthToken.trim().isNotEmpty}',
    );
    _socketService.connect(
      authToken: socketAuthToken ?? _apiClient.authToken,
      authHeaders: socketAuthHeaders,
      onConnectError: _onSocketConnectError,
      onNewMessage: _onNewMessageFromSocket,
      onFriendRequestReceived: _onFriendRequestReceivedFromSocket,
      onFriendRequestSent: _onFriendRequestSentFromSocket,
      onFriendRequestResponded: _onFriendRequestRespondedFromSocket,
      onFriendRequestCancelled: _onFriendRequestCancelledFromSocket,
      onFriendshipBlocked: _onFriendshipBlockedFromSocket,
      onFriendshipUnblocked: _onFriendshipUnblockedFromSocket,
      onFriendshipDeleted: _onFriendshipDeletedFromSocket,
      onFriendsStateUpdated: _onFriendsStateUpdatedFromSocket,
      onChannelInvited: _onChannelInvitedFromSocket,
      onChannelMemberRemoved: _onChannelMemberRemovedFromSocket,
      onChannelUpdated: _onChannelUpdatedFromSocket,
      onUserProfileUpdated: _onUserProfileUpdatedFromSocket,
      onMessageError: _onMessageErrorFromSocket,
      onLocationSnapshot: _onLocationSnapshotFromSocket,
      onLocationUpdate: _onLocationUpdateFromSocket,
      onLocationRemove: _onLocationRemoveFromSocket,
      onPresenceUpdated: _onPresenceUpdatedFromSocket,
    );
    _socketService.requestLiveLocationsSnapshot();
  }

  void _startSessionKeepAlive() {
    _sessionKeepAliveTimer?.cancel();
    _sessionKeepAliveTimer = Timer.periodic(const Duration(minutes: 8), (_) {
      unawaited(_performSessionKeepAliveTick());
    });
  }

  void _stopSessionKeepAlive() {
    _sessionKeepAliveTimer?.cancel();
    _sessionKeepAliveTimer = null;
  }

  Future<void> _performSessionKeepAliveTick() async {
    if (!_authProvider.isLoggedIn) return;
    if (!_isAppInForeground) return;
    try {
      final refreshed = await _apiClient.refreshSession();
      _rtLog('session keepalive refreshed=$refreshed');
      if (!refreshed) return;
      if (_socketService.isConnected) return;
      await _recoverSocketSession(reason: 'keepalive_socket_disconnected');
    } catch (_) {
      // Best-effort keepalive; retry next tick.
    }
  }

  void _onSocketConnectError(dynamic error) {
    final message = error?.toString() ?? '';
    _rtLog('socket connect_error callback=$message');
    if (!_isSocketAuthError(message)) return;
    unawaited(_recoverSocketSession(reason: 'socket_auth_error'));
  }

  bool _isSocketAuthError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('auth') ||
        normalized.contains('jwt') ||
        normalized.contains('expired') ||
        normalized.contains('token');
  }

  Future<void> _recoverSocketSession({required String reason}) async {
    if (_isRecoveringSocketSession) return;
    final now = DateTime.now();
    final last = _lastSocketRecoveryAt;
    if (last != null && now.difference(last) < const Duration(seconds: 10)) {
      return;
    }

    _isRecoveringSocketSession = true;
    _lastSocketRecoveryAt = now;
    _rtLog('socket recover start reason=$reason');
    try {
      final refreshed = await _apiClient.refreshSession();
      _rtLog('socket recover refreshSession=$refreshed');
      if (!refreshed) return;

      _socketService.disconnect();
      await _connectSocketWithLatestAuth();
      _scheduleSocialStateRefresh();
    } catch (error) {
      _rtLog('socket recover failed error=$error');
    } finally {
      _isRecoveringSocketSession = false;
    }
  }

  void _onNewMessageFromSocket(ChannelMessageModel message) {
    if (_shouldStoreInAppNotifications) {
      _pushNewMessageNotification(message);
    }
    _scheduleRealtimeMessageDerivedRefreshes();
    final incomingChannelId = message.channelId;
    if (_selectedChannel == null) {
      unawaited(refreshChannels(silent: true));
      return;
    }
    if (incomingChannelId <= 0 ||
        incomingChannelId != _selectedChannel!.channelId) {
      unawaited(refreshChannels(silent: true));
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
    _messages = [..._messages, enriched];
    _notifyStateChanged();
    unawaited(refreshChannels(silent: true));
  }

  void _onFriendRequestReceivedFromSocket(Map<String, dynamic> payload) {
    _rtLog('onFriendRequestReceived payload=$payload');
    final senderRaw = payload['sender'];
    final sender = senderRaw is Map<String, dynamic>
        ? senderRaw
        : senderRaw is Map
        ? Map<String, dynamic>.from(senderRaw)
        : const <String, dynamic>{};

    final senderId = _toInt(
      sender['id'] ?? sender['userId'] ?? sender['user_id'],
    );
    final meId = _authProvider.user?.id;
    if (meId != null && senderId == meId) return;

    final username = (sender['username'] ?? 'Utilisateur').toString().trim();
    final createdAt = _parseDate(
      payload['createdAt'] ?? payload['created_at'] ?? payload['date'],
    );
    final requestId = _toInt(payload['requestId'] ?? payload['request_id']);

    if (_shouldStoreInAppNotifications) {
      _prependNotification(
        AppNotificationModel(
          id: 'fr-$requestId-${createdAt.microsecondsSinceEpoch}',
          type: AppNotificationType.friendRequest,
          title: "Vous avez reçu une demande d'ami de $username",
          subtitle: _formatNotificationTime(createdAt),
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
    _scheduleSocialStateRefresh(delay: const Duration(milliseconds: 180));
  }

  void _onFriendRequestRespondedFromSocket(Map<String, dynamic> payload) {
    _rtLog('onFriendRequestResponded payload=$payload');
    _scheduleSocialStateRefresh();
  }

  void _onFriendRequestSentFromSocket(Map<String, dynamic> payload) {
    _rtLog('onFriendRequestSent payload=$payload');
    _scheduleSocialStateRefresh();
  }

  void _onFriendRequestCancelledFromSocket(Map<String, dynamic> payload) {
    _rtLog('onFriendRequestCancelled payload=$payload');
    _scheduleSocialStateRefresh();
  }

  void _onFriendshipBlockedFromSocket(Map<String, dynamic> payload) {
    _rtLog('onFriendshipBlocked payload=$payload');
    _scheduleSocialStateRefresh();
    unawaited(refreshChannels(silent: true));
  }

  void _onFriendshipUnblockedFromSocket(Map<String, dynamic> payload) {
    _rtLog('onFriendshipUnblocked payload=$payload');
    _scheduleSocialStateRefresh();
  }

  void _onFriendshipDeletedFromSocket(Map<String, dynamic> payload) {
    _rtLog('onFriendshipDeleted payload=$payload');
    _scheduleSocialStateRefresh();
    unawaited(refreshChannels(silent: true));
  }

  void _onFriendsStateUpdatedFromSocket(Map<String, dynamic> payload) {
    _rtLog('onFriendsStateUpdated payload=$payload');
    _scheduleSocialStateRefresh();
    unawaited(refreshChannels(silent: true));
  }

  void _onChannelInvitedFromSocket(Map<String, dynamic> payload) {
    _scheduleRealtimeChannelsRefresh();
    if (!_shouldStoreInAppNotifications) return;
    final now = DateTime.now();
    final channelName = (payload['channelName'] ?? payload['name'] ?? 'groupe')
        .toString()
        .trim();
    final channelId = _toInt(payload['channelId'] ?? payload['channel_id']);
    _prependNotification(
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

  void _onChannelMemberRemovedFromSocket(Map<String, dynamic> payload) {
    final channelId = _toInt(payload['channelId'] ?? payload['channel_id']);
    final removedUserId = _toInt(
      payload['removedUserId'] ?? payload['removed_user_id'],
    );
    final currentUserId = _authProvider.user?.id;

    _scheduleRealtimeChannelsRefresh();

    final selected = _selectedChannel;
    if (selected == null || selected.channelId != channelId) return;

    if (currentUserId != null && removedUserId == currentUserId) {
      _selectedChannel = null;
      _messages = const [];
      _channelMembers = const [];
      _notifyStateChanged();
      return;
    }

    unawaited(() async {
      try {
        _channelMembers = await _channelRepository.readChannelUsers(channelId);
        _notifyStateChanged();
      } catch (_) {
        // Keep real-time refresh best-effort for this event.
      }
    }());
  }

  void _onChannelUpdatedFromSocket(Map<String, dynamic> payload) {
    _rtLog('onChannelUpdated payload=$payload');
    _scheduleRealtimeChannelsRefresh();
  }

  void _onUserProfileUpdatedFromSocket(Map<String, dynamic> payload) {
    final userId = _toInt(
      payload['userId'] ?? payload['user_id'] ?? payload['id'],
    );
    if (userId <= 0) return;
    final usernameRaw = payload['username']?.toString();
    final avatarRaw = payload['avatar']?.toString();
    final bioRaw = payload['bio']?.toString();
    final statusRaw = payload['presence_status'] ?? payload['presenceStatus'];
    final normalizedPresence = PresenceUtils.normalize(statusRaw?.toString());

    var didChange = false;
    _allUsers = _allUsers
        .map((user) {
          if (user.id != userId) return user;
          didChange = true;
          return user.copyWith(
            username: usernameRaw?.trim().isNotEmpty == true
                ? usernameRaw?.trim()
                : user.username,
            avatar: avatarRaw ?? user.avatar,
            bio: bioRaw ?? user.bio,
            presenceStatus: normalizedPresence,
          );
        })
        .toList(growable: false);

    UserModel withUpdatedProfile(UserModel source) {
      return source.copyWith(
        username: usernameRaw?.trim().isNotEmpty == true
            ? usernameRaw!.trim()
            : source.username,
        avatar: avatarRaw ?? source.avatar,
        bio: bioRaw ?? source.bio,
        presenceStatus: normalizedPresence,
      );
    }

    FriendModel updateFriendModelWithDetails(FriendModel friend) {
      final details = friend.friendDetails;
      if (details == null || details.id != userId) return friend;
      didChange = true;
      return FriendModel(
        id: friend.id,
        userId: friend.userId,
        friendId: friend.friendId,
        status: friend.status,
        friendDetails: withUpdatedProfile(details),
      );
    }

    _friends = _friends
        .map(updateFriendModelWithDetails)
        .toList(growable: false);
    _incomingFriendRequests = _incomingFriendRequests
        .map(updateFriendModelWithDetails)
        .toList(growable: false);
    _outgoingFriendRequests = _outgoingFriendRequests
        .map(updateFriendModelWithDetails)
        .toList(growable: false);

    _blockedUsers = _blockedUsers
        .map((user) {
          if (user.id != userId) return user;
          didChange = true;
          return withUpdatedProfile(user);
        })
        .toList(growable: false);

    UserModel? updateDmPeer(UserModel? peer) {
      if (peer == null || peer.id != userId) return peer;
      didChange = true;
      return withUpdatedProfile(peer);
    }

    _channels = _channels
        .map((channel) {
          final dmPeer = updateDmPeer(channel.dmPeer);
          if (identical(dmPeer, channel.dmPeer)) return channel;
          return channel.copyWith(dmPeer: dmPeer);
        })
        .toList(growable: false);
    _publicChannels = _publicChannels
        .map((channel) {
          final dmPeer = updateDmPeer(channel.dmPeer);
          if (identical(dmPeer, channel.dmPeer)) return channel;
          return channel.copyWith(dmPeer: dmPeer);
        })
        .toList(growable: false);
    _selectedChannel = _selectedChannel?.copyWith(
      dmPeer: updateDmPeer(_selectedChannel?.dmPeer),
    );

    _channelMembers = _channelMembers
        .map((member) {
          if (member.id != userId) return member;
          didChange = true;
          return withUpdatedProfile(member);
        })
        .toList(growable: false);

    _messages = _messages
        .map((message) {
          final sender = message.sender;
          if (sender == null || sender.id != userId) return message;
          didChange = true;
          return ChannelMessageModel(
            messageId: message.messageId,
            content: message.content,
            channelId: message.channelId,
            senderId: message.senderId,
            status: message.status,
            createdAt: message.createdAt,
            sender: withUpdatedProfile(sender),
            imageUrl: message.imageUrl,
          );
        })
        .toList(growable: false);

    _presenceByUserId[userId] = normalizedPresence;

    final me = _authProvider.user;
    if (me != null && me.id == userId) {
      _authProvider.setUser(withUpdatedProfile(me));
      didChange = true;
    }

    if (didChange) {
      _notifyStateChanged();
    }
  }

  void _upsertIncomingRequestFromSocket({
    required Map<String, dynamic> payload,
    required Map<String, dynamic> sender,
    required int senderId,
    required int? meId,
  }) {
    if (senderId <= 0 || meId == null || meId <= 0) return;

    final requestId = _toInt(payload['requestId'] ?? payload['request_id']);
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

    final existingIndex = _incomingFriendRequests.indexWhere(
      (request) =>
          request.id == requestId ||
          (request.userId == senderId &&
              request.status.trim().toUpperCase() == 'PENDING'),
    );

    if (existingIndex >= 0) {
      final updated = [..._incomingFriendRequests];
      updated[existingIndex] = incoming;
      _incomingFriendRequests = updated;
    } else {
      _incomingFriendRequests = [incoming, ..._incomingFriendRequests];
    }

    _presenceByUserId[senderId] = PresenceUtils.normalize(
      senderUser.presenceStatus,
    );
    _notifyStateChanged();
  }

  void _scheduleRealtimeMessageDerivedRefreshes() {
    _scheduleRealtimeChannelsRefresh();
    _scheduleRealtimeProfileStatsRefresh();
  }

  void _scheduleRealtimeChannelsRefresh({
    Duration delay = const Duration(milliseconds: 260),
  }) {
    _realtimeChannelsRefreshDebounce?.cancel();
    _realtimeChannelsRefreshDebounce = Timer(delay, () {
      unawaited(_runRealtimeChannelsRefresh());
    });
  }

  Future<void> _runRealtimeChannelsRefresh() async {
    if (_isRefreshingRealtimeChannels) {
      _hasQueuedRealtimeChannelsRefresh = true;
      return;
    }
    _isRefreshingRealtimeChannels = true;
    try {
      await Future.wait([
        refreshChannels(silent: true),
        refreshPublicChannels(filter: _lastPublicChannelsFilter, silent: true),
      ]);
    } catch (_) {
      // Keep realtime refresh best-effort.
    } finally {
      _isRefreshingRealtimeChannels = false;
      if (_hasQueuedRealtimeChannelsRefresh) {
        _hasQueuedRealtimeChannelsRefresh = false;
        unawaited(_runRealtimeChannelsRefresh());
      }
    }
  }

  void _scheduleRealtimeProfileStatsRefresh({
    Duration delay = const Duration(milliseconds: 700),
  }) {
    _realtimeProfileStatsRefreshDebounce?.cancel();
    _realtimeProfileStatsRefreshDebounce = Timer(delay, () {
      unawaited(_runRealtimeProfileStatsRefresh());
    });
  }

  Future<void> _runRealtimeProfileStatsRefresh() async {
    if (_isRefreshingRealtimeProfileStats) {
      _hasQueuedRealtimeProfileStatsRefresh = true;
      return;
    }
    _isRefreshingRealtimeProfileStats = true;
    try {
      await _refreshCurrentUser();
      _realtimeStatsVersion++;
      _notifyStateChanged();
    } catch (_) {
      // Keep realtime refresh best-effort.
    } finally {
      _isRefreshingRealtimeProfileStats = false;
      if (_hasQueuedRealtimeProfileStatsRefresh) {
        _hasQueuedRealtimeProfileStatsRefresh = false;
        unawaited(_runRealtimeProfileStatsRefresh());
      }
    }
  }

  void _scheduleSocialStateRefresh({Duration delay = Duration.zero}) {
    _socialRefreshDebounce?.cancel();
    _socialRefreshDebounce = Timer(delay, () {
      unawaited(_runSocialStateRefresh());
    });
  }

  Future<void> _runSocialStateRefresh() async {
    if (_isRefreshingSocialState) {
      _hasQueuedSocialRefresh = true;
      return;
    }
    _isRefreshingSocialState = true;
    try {
      await _refreshSocialStateFromSocket();
    } finally {
      _isRefreshingSocialState = false;
      if (_hasQueuedSocialRefresh) {
        _hasQueuedSocialRefresh = false;
        unawaited(_runSocialStateRefresh());
      }
    }
  }

  Future<void> _refreshSocialStateFromSocket() async {
    await Future.wait([
      refreshFriends(silent: true),
      refreshFriendRequests(silent: true),
      refreshBlockedUsers(silent: true),
      refreshUsers(silent: true),
    ]);
    final removedHiddenLocations = _pruneHiddenLiveLocations();
    _socketService.requestLiveLocationsSnapshot();
    if (removedHiddenLocations) {
      _notifyStateChanged();
    }
  }

  void _onMessageErrorFromSocket(String message) {
    final normalized = message.trim();
    _messageError = normalized.isEmpty
        ? 'DM impossible: vous devez être ami actif ou activer les DM non-amis.'
        : normalized;
    _notifyStateChanged();
  }

  void publishMyLiveLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
  }) {
    final me = _authProvider.user;
    if (me == null) return;
    final previous = _liveLocationsByUserId[me.id];
    final hasMovedEnough =
        previous == null ||
        _distanceInMeters(
              previous.latitude,
              previous.longitude,
              latitude,
              longitude,
            ) >=
            3;
    if (!hasMovedEnough) return;
    _liveLocationsByUserId[me.id] = LiveUserLocationModel(
      userId: me.id,
      username: me.username,
      avatar: me.avatar,
      latitude: latitude,
      longitude: longitude,
      updatedAt: DateTime.now().toUtc(),
    );
    _socketService.publishLiveLocation(
      userId: me.id,
      username: me.username,
      avatar: me.avatar,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
    );
    _notifyStateChanged();
  }

  void stopMyLiveLocationSharing() {
    final me = _authProvider.user;
    if (me == null) return;
    _liveLocationsByUserId.remove(me.id);
    _socketService.stopLiveLocationSharing(userId: me.id);
    _notifyStateChanged();
  }

  void _onLocationSnapshotFromSocket(List<dynamic> payload) {
    final meId = _authProvider.user?.id;
    final next = <int, LiveUserLocationModel>{};
    for (final entry in payload) {
      if (entry is! Map) continue;
      final model = LiveUserLocationModel.fromJson(
        Map<String, dynamic>.from(entry),
      );
      if (!_isLocationPayloadValid(model)) continue;
      if (!_shouldDisplayLocationForUser(model.userId)) continue;
      next[model.userId] = model;
    }
    if (meId != null && _liveLocationsByUserId.containsKey(meId)) {
      next[meId] = _liveLocationsByUserId[meId]!;
    }
    _liveLocationsByUserId
      ..clear()
      ..addAll(next);
    _notifyStateChanged();
  }

  void _onLocationUpdateFromSocket(Map<String, dynamic> payload) {
    final model = LiveUserLocationModel.fromJson(payload);
    if (!_isLocationPayloadValid(model)) return;
    if (!_shouldDisplayLocationForUser(model.userId)) return;
    _liveLocationsByUserId[model.userId] = model;
    _notifyStateChanged();
  }

  void _onLocationRemoveFromSocket(int userId) {
    if (!_liveLocationsByUserId.containsKey(userId)) return;
    _liveLocationsByUserId.remove(userId);
    _notifyStateChanged();
  }

  void _onPresenceUpdatedFromSocket(Map<String, dynamic> payload) {
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
    _presenceByUserId[userId] = normalized;

    final me = _authProvider.user;
    if (me != null && me.id == userId) {
      _authProvider.setUser(me.copyWith(presenceStatus: normalized));
      return;
    }
    _notifyStateChanged();
  }

}
