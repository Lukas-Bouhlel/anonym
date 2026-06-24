part of 'app_providers.dart';

/// Operations de rafraichissement des donnees applicatives.
extension AppProviderRefreshX on AppProvider {
  Future<void> refreshAll() async {
    if (!_authProvider.isLoggedIn) return;
    _isBootstrapping = true;
    _errorMessage = null;
    _notifyStateChanged();

    try {
      await _loadReadNotificationIds();
      await Future.wait([
        _refreshCurrentUser(),
        refreshFriends(silent: true),
        refreshFriendRequests(silent: true),
        refreshBlockedUsers(silent: true),
        refreshUsers(silent: true),
        refreshChannels(silent: true),
        refreshPublicChannels(silent: true),
        refreshShop(silent: true),
        refreshInventory(silent: true),
        refreshInvoices(silent: true),
      ]);
      _pruneHiddenLiveLocations();
      _socketService.requestLiveLocationsSnapshot();
    } catch (e) {
      _errorMessage = ApiErrorParser.parse(
        e,
        fallback: 'Chargement impossible',
      );
    } finally {
      _isBootstrapping = false;
      _notifyStateChanged();
    }
  }

  Future<void> refreshFriends({bool silent = false}) {
    return _socialRefreshDomainService.refreshFriends(silent: silent);
  }

  Future<void> refreshFriendRequests({bool silent = false}) {
    return _socialRefreshDomainService.refreshFriendRequests(silent: silent);
  }

  Future<void> refreshBlockedUsers({bool silent = false}) {
    return _socialRefreshDomainService.refreshBlockedUsers(silent: silent);
  }

  Future<void> refreshUsers({bool silent = false}) {
    return _socialRefreshDomainService.refreshUsers(silent: silent);
  }

  Future<UserModel?> hydrateUserDetails(
    int userId, {
    bool forceRefresh = false,
  }) {
    return _socialRefreshDomainService.hydrateUserDetails(
      userId,
      forceRefresh: forceRefresh,
    );
  }

  Future<void> refreshChannels({bool silent = false}) {
    return _channelsRefreshDomainService.refreshChannels(silent: silent);
  }

  Future<void> refreshPublicChannels({
    String filter = 'all',
    bool silent = false,
  }) {
    return _channelsRefreshDomainService.refreshPublicChannels(
      filter: filter,
      silent: silent,
    );
  }

  Future<List<ChannelModel>> loadJoinDirectoryChannels({
    String filter = 'all',
  }) {
    return _channelsRefreshDomainService.loadJoinDirectoryChannels(
      filter: filter,
    );
  }

  Future<List<ChannelModel>> publicGroupsForUser(
    int userId, {
    bool forceRefresh = false,
  }) {
    return _channelsRefreshDomainService.publicGroupsForUser(
      userId,
      forceRefresh: forceRefresh,
    );
  }

  Future<void> refreshShop({bool silent = false}) {
    return _commerceRefreshDomainService.refreshShop(silent: silent);
  }

  Future<void> refreshInventory({bool silent = false}) {
    return _commerceRefreshDomainService.refreshInventory(silent: silent);
  }

  Future<void> refreshInvoices({bool silent = false}) {
    return _commerceRefreshDomainService.refreshInvoices(silent: silent);
  }
}
