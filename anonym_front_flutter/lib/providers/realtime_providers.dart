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
    _rtLog(
      'boot socket user=${_authProvider.user?.id} hasAuthCookies=${socketAuthHeaders.isNotEmpty}',
    );
    _socketService.connect(
      authHeaders: socketAuthHeaders,
      onConnectError: _onSocketConnectError,
      onNewMessage: _onNewMessageFromSocket,
      onMessageUpdated: _onMessageUpdatedFromSocket,
      onMessageDeleted: _onMessageDeletedFromSocket,
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

  void _startSessionKeepAlive() => _realtimeCoordinator.startSessionKeepAlive();

  void _stopSessionKeepAlive() => _realtimeCoordinator.stopSessionKeepAlive();

  void _onSocketConnectError(dynamic error) =>
      _realtimeCoordinator.onSocketConnectError(error);

  Future<void> _recoverSocketSession({required String reason}) =>
      _realtimeCoordinator.recoverSocketSession(reason: reason);

  void _onNewMessageFromSocket(ChannelMessageModel message) =>
      _realtimeEvents.onNewMessageFromSocket(message);

  void _onMessageUpdatedFromSocket(ChannelMessageModel message) =>
      _realtimeEvents.onMessageUpdatedFromSocket(message);

  void _onMessageDeletedFromSocket(Map<String, dynamic> payload) =>
      _realtimeEvents.onMessageDeletedFromSocket(payload);

  void _onFriendRequestReceivedFromSocket(Map<String, dynamic> payload) =>
      _realtimeEvents.onFriendRequestReceivedFromSocket(payload);

  void _onFriendRequestRespondedFromSocket(Map<String, dynamic> payload) =>
      _realtimeEvents.onFriendRequestRespondedFromSocket(payload);

  void _onFriendRequestSentFromSocket(Map<String, dynamic> payload) =>
      _realtimeEvents.onFriendRequestSentFromSocket(payload);

  void _onFriendRequestCancelledFromSocket(Map<String, dynamic> payload) =>
      _realtimeEvents.onFriendRequestCancelledFromSocket(payload);

  void _onFriendshipBlockedFromSocket(Map<String, dynamic> payload) =>
      _realtimeEvents.onFriendshipBlockedFromSocket(payload);

  void _onFriendshipUnblockedFromSocket(Map<String, dynamic> payload) =>
      _realtimeEvents.onFriendshipUnblockedFromSocket(payload);

  void _onFriendshipDeletedFromSocket(Map<String, dynamic> payload) =>
      _realtimeEvents.onFriendshipDeletedFromSocket(payload);

  void _onFriendsStateUpdatedFromSocket(Map<String, dynamic> payload) =>
      _realtimeEvents.onFriendsStateUpdatedFromSocket(payload);

  void _onChannelInvitedFromSocket(Map<String, dynamic> payload) =>
      _realtimeEvents.onChannelInvitedFromSocket(payload);

  void _onChannelMemberRemovedFromSocket(Map<String, dynamic> payload) =>
      _realtimeEvents.onChannelMemberRemovedFromSocket(payload);

  void _onChannelUpdatedFromSocket(Map<String, dynamic> payload) =>
      _realtimeEvents.onChannelUpdatedFromSocket(payload);

  void _onMessageErrorFromSocket(String message) =>
      _realtimeEvents.onMessageErrorFromSocket(message);

  void _onLocationSnapshotFromSocket(List<dynamic> payload) =>
      _realtimeEvents.onLocationSnapshotFromSocket(payload);

  void _onLocationUpdateFromSocket(Map<String, dynamic> payload) =>
      _realtimeEvents.onLocationUpdateFromSocket(payload);

  void _onLocationRemoveFromSocket(int userId) =>
      _realtimeEvents.onLocationRemoveFromSocket(userId);

  void _onPresenceUpdatedFromSocket(Map<String, dynamic> payload) =>
      _realtimeEvents.onPresenceUpdatedFromSocket(payload);

  void _scheduleRealtimeMessageDerivedRefreshes() =>
      _realtimeEvents.scheduleRealtimeMessageDerivedRefreshes();

  void _scheduleSocialStateRefresh({Duration delay = Duration.zero}) =>
      _realtimeEvents.scheduleSocialStateRefresh(delay: delay);

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
    _markPresenceStateChanged();
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
    _markPresenceStateChanged();
    _socketService.stopLiveLocationSharing(userId: me.id);
    _notifyStateChanged();
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

    final liveLocation = _liveLocationsByUserId[userId];
    if (liveLocation != null) {
      _liveLocationsByUserId[userId] = liveLocation.copyWith(
        username: usernameRaw?.trim().isNotEmpty == true
            ? usernameRaw!.trim()
            : liveLocation.username,
        avatar: avatarRaw ?? liveLocation.avatar,
      );
      _markPresenceStateChanged();
      didChange = true;
    }

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
    _markPresenceStateChanged();
    final me = _authProvider.user;
    if (me != null && me.id == userId) {
      _authProvider.setUser(withUpdatedProfile(me));
      didChange = true;
    }
    if (didChange) _notifyStateChanged();
  }
}
