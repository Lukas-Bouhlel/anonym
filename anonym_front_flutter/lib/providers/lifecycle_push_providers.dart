part of 'app_providers.dart';

/// Gestion du cycle de vie app, presence utilisateur et push notifications.
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
      _markPresenceStateChanged();
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
    _notificationService.handleForegroundPushMessage(message);
  }

  void _handlePushMessageOpen(dynamic message) {
    _notificationService.handlePushMessageOpen(message);
  }

  bool _isLocationPayloadValid(LiveUserLocationModel value) {
    return _presenceService.isLocationPayloadValid(value);
  }

  Set<int> get _visibleLocationUserIds {
    return _presenceService.visibleLocationUserIds();
  }

  bool _shouldDisplayLocationForUser(int userId) {
    return _presenceService.shouldDisplayLocationForUser(userId);
  }

  bool _pruneHiddenLiveLocations() {
    return _presenceService.pruneHiddenLiveLocations();
  }

  double _distanceInMeters(double lat1, double lon1, double lat2, double lon2) {
    return _presenceService.distanceInMeters(lat1, lon1, lat2, lon2);
  }

  void _pushNewMessageNotification(ChannelMessageModel message) {
    _notificationService.pushNewMessageNotification(message);
  }

  void _prependNotification(AppNotificationModel value) {
    _notificationService.prependNotification(value);
  }

  bool get _shouldStoreInAppNotifications =>
      _notificationService.shouldStoreInAppNotifications;

  Future<void> _loadReadNotificationIds() async {
    await _notificationService.loadReadNotificationIds();
  }

  Future<void> _persistReadNotificationIds() async {
    await _notificationService.persistReadNotificationIds();
  }

  String _formatNotificationTime(DateTime value) {
    return _parsingService.formatNotificationTime(value);
  }

  DateTime _parseDate(dynamic raw) {
    return _parsingService.parseDate(raw);
  }

  int _toInt(dynamic raw) {
    return _parsingService.toInt(raw);
  }

  bool _isActiveFriendStatus(String status) {
    return _presenceService.isActiveFriendStatus(status);
  }

  bool _isBlockedFriendStatus(String status) {
    return _presenceService.isBlockedFriendStatus(status);
  }

  Future<void> _refreshCurrentUser() async {
    final me = await _accountRepository.readAccount();
    if (me.id > 0) {
      _presenceByUserId[me.id] = PresenceUtils.normalize(me.presenceStatus);
      _markPresenceStateChanged();
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
    _markPresenceStateChanged();
    _notifyStateChanged();
  }

  Future<void> _wrap(
    Future<void> Function() callback, {
    required String fallbackMessage,
    bool silent = false,
  }) async {
    await _mutationService.run(
      callback,
      fallbackMessage: fallbackMessage,
      silent: silent,
    );
  }
}
