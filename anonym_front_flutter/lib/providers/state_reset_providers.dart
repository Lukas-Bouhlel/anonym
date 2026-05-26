part of 'app_providers.dart';

/// Réinitialisation complète de l'état du [AppProvider].
extension AppProviderStateResetX on AppProvider {
  void _resetState() {
    _activeUserId = null;
    _friends = const [];
    _incomingFriendRequests = const [];
    _outgoingFriendRequests = const [];
    _blockedUsers = const [];
    _channels = const [];
    _publicChannels = const [];
    _selectedChannel = null;
    _channelMembers = const [];
    _messages = const [];
    _notifications = const [];
    _readNotificationIds = <String>{};
    _shopItems = const [];
    _inventoryItems = const [];
    _invoices = const [];
    _allUsers = const [];
    _liveLocationsByUserId.clear();
    _presenceByUserId.clear();
    _publicGroupsByUserFuture.clear();
    _userDetailsHydrationById.clear();
    _socialRefreshDebounce?.cancel();
    _socialRefreshDebounce = null;
    _realtimeChannelsRefreshDebounce?.cancel();
    _realtimeChannelsRefreshDebounce = null;
    _realtimeProfileStatsRefreshDebounce?.cancel();
    _realtimeProfileStatsRefreshDebounce = null;
    _stopSessionKeepAlive();
    _isRecoveringSocketSession = false;
    _lastSocketRecoveryAt = null;
    _isRefreshingSocialState = false;
    _hasQueuedSocialRefresh = false;
    _isRefreshingRealtimeChannels = false;
    _hasQueuedRealtimeChannelsRefresh = false;
    _isRefreshingRealtimeProfileStats = false;
    _hasQueuedRealtimeProfileStatsRefresh = false;
    _realtimeStatsVersion = 0;
    _lastPublicChannelsFilter = 'all';
    _manualPresenceOverride = null;
    _errorMessage = null;
    _messageError = null;
    _isBootstrapping = false;
    _isLoadingMessages = false;
    _isSubmitting = false;
    _socketService.disconnect();
    _pushTokenRefreshSubscription?.cancel();
    _pushOpenedAppSubscription?.cancel();
    _pushForegroundMessageSubscription?.cancel();
    _pushTokenRefreshSubscription = null;
    _pushOpenedAppSubscription = null;
    _pushForegroundMessageSubscription = null;
    _lastRegisteredPushToken = null;
    _notifyStateChanged();
  }
}

