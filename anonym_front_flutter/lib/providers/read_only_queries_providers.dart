part of 'app_providers.dart';

/// Read-only queries extracted from [AppProvider] to keep core orchestration
/// focused on state transitions and side effects.
extension AppProviderReadOnlyQueriesX on AppProvider {
  UserModel? userById(int userId) {
    if (userId <= 0) return null;
    for (final user in _allUsers) {
      if (user.id == userId) return user;
    }
    return null;
  }

  String? activeFrameUrlForUser(int userId) {
    return _socialDomainService.resolveSharedProfileFrameUrl(userId);
  }

  String presenceStatusForUser(int userId, {bool isCurrentUser = false}) {
    return PresenceUtils.effectiveForViewer(
      _presenceByUserId[userId],
      isCurrentUser: isCurrentUser,
    );
  }

  String presenceLabelForUser(int userId, {bool isCurrentUser = false}) {
    return PresenceUtils.label(
      _presenceByUserId[userId],
      isCurrentUser: isCurrentUser,
    );
  }

  bool isFriendRequestPending({int? userId, String? username}) {
    if (userId != null &&
        _outgoingFriendRequests.any((request) => request.friendId == userId)) {
      return true;
    }
    final normalized = username?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return false;
    return _outgoingFriendRequests.any((request) {
      final requestName = request.friendDetails?.username.trim().toLowerCase();
      return requestName == normalized;
    });
  }

  List<UserModel> get discoverableUsers {
    final me = _authProvider.user?.id;
    final friendIds = _friends
        .where((friend) => _isActiveFriendStatus(friend.status))
        .map((friend) => friend.friendId)
        .toSet();
    final outgoingIds = _outgoingFriendRequests
        .map((request) => request.friendId)
        .toSet();
    final incomingIds = _incomingFriendRequests
        .map((request) => request.userId)
        .toSet();
    final blockedIds = _blockedUsers.map((user) => user.id).toSet();

    return _allUsers
        .where((user) {
          if (user.id == me) return false;
          if (friendIds.contains(user.id)) return false;
          if (outgoingIds.contains(user.id)) return false;
          if (incomingIds.contains(user.id)) return false;
          if (blockedIds.contains(user.id)) return false;
          return true;
        })
        .toList(growable: false);
  }

  List<FriendModel> get availableFriendsForSelectedChannel {
    final selected = _selectedChannel;
    if (selected == null) return const [];
    final memberIds = _channelMembers.map((member) => member.id).toSet();
    return _friends
        .where(
          (friend) =>
              friend.status.trim().toUpperCase() == 'ACTIVE' &&
              !memberIds.contains(friend.friendId) &&
              friend.friendDetails != null,
        )
        .toList(growable: false);
  }

  bool isArticleOwned(int articleId) {
    return _inventoryItems.any((item) => item.articleId == articleId);
  }

  InventoryItemModel? inventoryByArticleId(int articleId) {
    try {
      return _inventoryItems.firstWhere((item) => item.articleId == articleId);
    } catch (_) {
      return null;
    }
  }
}
