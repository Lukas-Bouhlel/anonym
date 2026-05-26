part of 'app_providers.dart';

/// Gestion du cycle de vie app, présence utilisateur et push notifications.
extension AppProviderLifecyclePushX on AppProvider {
  Future<void> _applyLifecyclePresence(AppLifecycleState state) async {
    if (_manualPresenceOverride == PresenceUtils.dnd ||
        _manualPresenceOverride == PresenceUtils.invisible) {
      return;
    }
    switch (state) {
      case AppLifecycleState.resumed:
        await _setPresenceSilently(PresenceUtils.online);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        await _setPresenceSilently(PresenceUtils.idle);
        break;
      case AppLifecycleState.detached:
        await _setPresenceSilently(PresenceUtils.invisible);
        _socketService.disconnect();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _setPresenceSilently(String status) async {
    final me = _authProvider.user;
    if (me == null || me.id <= 0) return;
    final normalized = PresenceUtils.normalize(status);
    final current = PresenceUtils.normalize(_presenceByUserId[me.id]);
    if (current == normalized) return;

    try {
      await _accountRepository.updatePresenceStatus(normalized);
      _presenceByUserId[me.id] = normalized;
      _authProvider.setUser(me.copyWith(presenceStatus: normalized));
    } catch (_) {
      // Keep lifecycle transitions best-effort without surfacing noisy errors.
    }
  }

  void _sendInvisibleAndDisconnect() {
    _stopSessionKeepAlive();
    final me = _authProvider.user;
    if (me != null && me.id > 0) {
      _accountRepository
          .updatePresenceStatus(PresenceUtils.invisible)
          .catchError((_) {});
    }
    final token = _lastRegisteredPushToken;
    if (token != null && token.isNotEmpty) {
      _accountRepository.unregisterPushToken(token: token).catchError((_) {});
    }
    _pushNotificationService.deleteToken();
    _socketService.disconnect();
  }

  Future<void> _setupPushNotifications() async {
    final ready = await _pushNotificationService.initializeForDevice();
    if (!ready) return;
    await _syncCurrentPushToken();

    _pushTokenRefreshSubscription?.cancel();
    _pushTokenRefreshSubscription = _pushNotificationService.onTokenRefresh
        .listen((token) {
          _syncPushToken(token);
        });

    _pushOpenedAppSubscription?.cancel();
    _pushOpenedAppSubscription = _pushNotificationService.onMessageOpenedApp
        .listen(_handlePushMessageOpen);

    _pushForegroundMessageSubscription?.cancel();
    _pushForegroundMessageSubscription = _pushNotificationService.onMessage
        .listen(_handleForegroundPushMessage);

    final initialMessage = await _pushNotificationService.getInitialMessage();
    if (initialMessage != null) {
      _handlePushMessageOpen(initialMessage);
    }
  }

  Future<void> _syncCurrentPushToken() async {
    final token = await _pushNotificationService.getToken();
    if (token == null || token.trim().isEmpty) return;
    await _syncPushToken(token);
  }

  Future<void> _syncPushToken(String token) async {
    final me = _authProvider.user;
    final normalized = token.trim();
    if (me == null || normalized.isEmpty) return;
    if (_lastRegisteredPushToken == normalized) return;
    try {
      await _accountRepository.registerPushToken(
        token: normalized,
        platform: AccountRepository.currentDevicePlatform(),
      );
      _lastRegisteredPushToken = normalized;
    } catch (_) {
      // Keep push token sync best-effort.
    }
  }

  void _handleForegroundPushMessage(dynamic message) {
    if (message is! RemoteMessage) return;
    if (_shouldStoreInAppNotifications) {
      _appendPushNotification(message);
    }
  }

  void _handlePushMessageOpen(dynamic message) {
    if (message is! RemoteMessage) return;
    _appendPushNotification(message, forceStore: true);
    final channelId = _toInt(
      message.data['channelId'] ??
          message.data['channel_id'] ??
          message.data['conversation_id'],
    );
    if (channelId > 0) {
      openChannelById(channelId);
    }
  }

  void _appendPushNotification(
    RemoteMessage message, {
    bool forceStore = false,
  }) {
    if (!forceStore && !_shouldStoreInAppNotifications) return;
    final data = message.data;
    final eventType = (data['event'] ?? data['type'] ?? '').toString().trim();
    if (eventType == 'newMessage') {
      final senderId = _toInt(data['senderId'] ?? data['sender_id']);
      final meId = _authProvider.user?.id;
      if (meId != null && senderId == meId) return;
      final senderName =
          (data['senderUsername'] ?? data['sender_username'] ?? '')
              .toString()
              .trim();
      final channelId = _toInt(data['channelId'] ?? data['channel_id']);
      final now = DateTime.now();
      _prependNotification(
        AppNotificationModel(
          id: 'push-msg-${data['id'] ?? now.microsecondsSinceEpoch}',
          type: AppNotificationType.newMessage,
          title: senderName.isEmpty
              ? 'Vous avez reçu un nouveau message'
              : 'Vous avez reçu un nouveau message de $senderName',
          subtitle: _formatNotificationTime(now),
          createdAt: now,
          relatedUserId: senderId > 0 ? senderId : null,
          relatedChannelId: channelId > 0 ? channelId : null,
        ),
      );
      _scheduleRealtimeMessageDerivedRefreshes();
      return;
    }
    if (eventType == 'friendRequestReceived') {
      final senderId = _toInt(data['senderId'] ?? data['sender_id']);
      final senderName =
          (data['senderUsername'] ?? data['sender_username'] ?? '')
              .toString()
              .trim();
      final now = DateTime.now();
      _prependNotification(
        AppNotificationModel(
          id: 'push-fr-${data['requestId'] ?? now.microsecondsSinceEpoch}',
          type: AppNotificationType.friendRequest,
          title: senderName.isEmpty
              ? "Vous avez reçu une demande d'ami"
              : "Vous avez reçu une demande d'ami de $senderName",
          subtitle: _formatNotificationTime(now),
          createdAt: now,
          relatedUserId: senderId > 0 ? senderId : null,
        ),
      );
    }
  }

  bool _isLocationPayloadValid(LiveUserLocationModel value) {
    if (value.userId <= 0) return false;
    if (value.latitude < -90 || value.latitude > 90) return false;
    if (value.longitude < -180 || value.longitude > 180) return false;
    return true;
  }

  Set<int> get _visibleLocationUserIds {
    final visible = <int>{};
    final meId = _authProvider.user?.id;
    if (meId != null && meId > 0) {
      visible.add(meId);
    }
    for (final friend in _friends) {
      if (!_isActiveFriendStatus(friend.status)) continue;
      if (friend.friendId <= 0) continue;
      visible.add(friend.friendId);
    }
    return visible;
  }

  bool _shouldDisplayLocationForUser(int userId) {
    if (userId <= 0) return false;
    return _visibleLocationUserIds.contains(userId);
  }

  bool _pruneHiddenLiveLocations() {
    if (_liveLocationsByUserId.isEmpty) return false;
    final visibleIds = _visibleLocationUserIds;
    final removedIds = _liveLocationsByUserId.keys
        .where((userId) => !visibleIds.contains(userId))
        .toList(growable: false);
    if (removedIds.isEmpty) return false;
    for (final userId in removedIds) {
      _liveLocationsByUserId.remove(userId);
    }
    return true;
  }

  double _distanceInMeters(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  double _toRadians(double deg) => deg * 0.017453292519943295;

  void _pushNewMessageNotification(ChannelMessageModel message) {
    final meId = _authProvider.user?.id;
    final senderId = message.senderId ?? message.sender?.id;
    if (meId != null && senderId == meId) return;

    final selectedId = _selectedChannel?.channelId;
    if (selectedId != null && selectedId == message.channelId) {
      // User is already in this conversation: no toast/notification needed.
      return;
    }

    final senderName = message.sender?.username.trim();
    final safeSenderName = (senderName == null || senderName.isEmpty)
        ? 'Utilisateur'
        : senderName;
    final createdAt = message.createdAt ?? DateTime.now();

    _prependNotification(
      AppNotificationModel(
        id: 'msg-${message.messageId}-${createdAt.microsecondsSinceEpoch}',
        type: AppNotificationType.newMessage,
        title: 'Vous avez reçu un nouveau message de $safeSenderName',
        subtitle: _formatNotificationTime(createdAt),
        createdAt: createdAt,
        avatarUrl: message.sender?.avatar ?? message.imageUrl,
        relatedUserId: senderId,
        relatedChannelId: message.channelId > 0 ? message.channelId : null,
      ),
    );
  }

  void _prependNotification(AppNotificationModel value) {
    final incoming = value.copyWith(
      isRead: _readNotificationIds.contains(value.id),
    );
    final deduped = _notifications.where((item) => item.id != incoming.id);
    final next = <AppNotificationModel>[incoming, ...deduped];
    _notifications = next.take(100).toList(growable: false);
    _notifyStateChanged();
  }

  bool get _shouldStoreInAppNotifications => !_isAppInForeground;

  Future<void> _loadReadNotificationIds() async {
    final meId = _authProvider.user?.id;
    if (meId == null || meId <= 0) {
      _readNotificationIds = <String>{};
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final stored =
        prefs.getStringList(_readNotificationsStorageKey(meId)) ??
        const <String>[];
    _readNotificationIds = stored.toSet();
  }

  Future<void> _persistReadNotificationIds() async {
    final meId = _authProvider.user?.id;
    if (meId == null || meId <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _readNotificationsStorageKey(meId),
      _readNotificationIds.toList(growable: false),
    );
  }

  String _readNotificationsStorageKey(int userId) =>
      'notifications_read_ids_v1_user_$userId';

  String _formatNotificationTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return "Aujourd'hui à $hour:$minute";
  }

  DateTime _parseDate(dynamic raw) {
    if (raw is DateTime) return raw;
    if (raw is String) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  int _toInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw) ?? 0;
    return 0;
  }

  bool _isActiveFriendStatus(String status) {
    final normalized = status.trim().toUpperCase();
    return normalized == 'ACTIVE';
  }

  bool _isBlockedFriendStatus(String status) {
    final normalized = status.trim().toUpperCase();
    return normalized == 'BLOCKED' || normalized == 'BLOQUED';
  }

  String _normalizePublicChannelFilter(String filter) {
    final normalized = filter.trim().toLowerCase();
    switch (normalized) {
      case 'joined':
      case 'discover':
      case 'all':
        return normalized;
      default:
        return 'all';
    }
  }

  List<ChannelModel> _buildDiscoverTopChannels(List<ChannelModel> channels) {
    final discoverGroups = channels
        .where((channel) {
          final type = channel.channelType.trim().toUpperCase();
          final visibility = channel.visibility.trim().toUpperCase();
          return type == 'GROUP' && visibility == 'PUBLIC';
        })
        .toList(growable: false);

    discoverGroups.sort(
      (a, b) => (b.reputationScore ?? 0).compareTo(a.reputationScore ?? 0),
    );
    return discoverGroups.take(10).toList(growable: false);
  }

  List<ChannelModel> _excludePrivateDmChannels(List<ChannelModel> channels) {
    return channels
        .where(
          (channel) => channel.channelType.trim().toUpperCase() != 'PRIVATE_DM',
        )
        .toList(growable: false);
  }

  Future<void> _refreshCurrentUser() async {
    final me = await _accountRepository.readAccount();
    if (me.id > 0) {
      _presenceByUserId[me.id] = PresenceUtils.normalize(me.presenceStatus);
    }
    _authProvider.setUser(me);
  }

  void _upsertUserInAllUsers(UserModel incoming) {
    if (incoming.id <= 0) return;
    final existingIndex = _allUsers.indexWhere(
      (user) => user.id == incoming.id,
    );
    if (existingIndex < 0) {
      _allUsers = [..._allUsers, incoming];
    } else {
      final next = [..._allUsers];
      next[existingIndex] = incoming;
      _allUsers = next;
    }
    _presenceByUserId[incoming.id] = PresenceUtils.normalize(
      incoming.presenceStatus,
    );
    _notifyStateChanged();
  }

  Future<void> _wrap(
    Future<void> Function() callback, {
    required String fallbackMessage,
    bool silent = false,
  }) async {
    if (!silent) {
      _isSubmitting = true;
      _errorMessage = null;
      _notifyStateChanged();
    }
    try {
      await callback();
    } catch (e) {
      _errorMessage = ApiErrorParser.parse(e, fallback: fallbackMessage);
    } finally {
      if (!silent) _isSubmitting = false;
      _notifyStateChanged();
    }
  }

}
