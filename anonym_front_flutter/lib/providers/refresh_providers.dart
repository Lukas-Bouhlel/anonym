part of 'app_providers.dart';

/// Opérations de rafraîchissement des données applicatives.
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

  Future<void> refreshFriends({bool silent = false}) async {
    await _wrap(
      () async {
        _friends = await _friendsRepository.readAll();
        for (final friend in _friends) {
          final details = friend.friendDetails;
          if (details == null || details.id <= 0) continue;
          _presenceByUserId[details.id] = PresenceUtils.normalize(
            details.presenceStatus,
          );
        }
      },
      silent: silent,
      fallbackMessage: 'Impossible de charger les amis',
    );
  }

  Future<void> refreshFriendRequests({bool silent = false}) async {
    await _wrap(
      () async {
        final responses = await Future.wait([
          _friendsRepository.readIncomingRequests(),
          _friendsRepository.readOutgoingRequests(),
        ]);
        _incomingFriendRequests = responses[0];
        _outgoingFriendRequests = responses[1];
        for (final request in _incomingFriendRequests) {
          final details = request.friendDetails;
          if (details == null || details.id <= 0) continue;
          _presenceByUserId[details.id] = PresenceUtils.normalize(
            details.presenceStatus,
          );
        }
        for (final request in _outgoingFriendRequests) {
          final details = request.friendDetails;
          if (details == null || details.id <= 0) continue;
          _presenceByUserId[details.id] = PresenceUtils.normalize(
            details.presenceStatus,
          );
        }
      },
      silent: silent,
      fallbackMessage: 'Impossible de charger les demandes d\'amis',
    );
  }

  Future<void> refreshBlockedUsers({bool silent = false}) async {
    await _wrap(
      () async {
        final blockedFromApi = await _friendsRepository.readBlockedUsers();
        final blockedFromFriends = _friends
            .where((friend) => _isBlockedFriendStatus(friend.status))
            .map((friend) => friend.friendDetails)
            .whereType<UserModel>();
        final byId = <int, UserModel>{
          for (final user in blockedFromApi) user.id: user,
        };
        for (final user in blockedFromFriends) {
          if (user.id > 0) byId[user.id] = user;
        }
        _blockedUsers = byId.values.toList(growable: false);
        for (final user in _blockedUsers) {
          if (user.id <= 0) continue;
          _presenceByUserId[user.id] = PresenceUtils.normalize(
            user.presenceStatus,
          );
        }
      },
      silent: silent,
      fallbackMessage: 'Impossible de charger les utilisateurs bloqués',
    );
  }

  Future<void> refreshUsers({bool silent = false}) async {
    await _wrap(
      () async {
        _allUsers = await _accountRepository.readAllUsers();
        for (final user in _allUsers) {
          if (user.id <= 0) continue;
          _presenceByUserId[user.id] = PresenceUtils.normalize(
            user.presenceStatus,
          );
        }
      },
      silent: silent,
      fallbackMessage: 'Impossible de charger les utilisateurs',
    );
  }

  Future<UserModel?> hydrateUserDetails(
    int userId, {
    bool forceRefresh = false,
  }) async {
    if (userId <= 0) return null;

    if (!forceRefresh) {
      final existing = userById(userId);
      if (existing != null && existing.inventories.isNotEmpty) {
        return existing;
      }
      final inflight = _userDetailsHydrationById[userId];
      if (inflight != null) return inflight;
    }

    final future = () async {
      try {
        final fetched = await _accountRepository.readUserById(userId);
        _upsertUserInAllUsers(fetched);
        return fetched;
      } catch (_) {
        return null;
      } finally {
        _userDetailsHydrationById.remove(userId);
      }
    }();

    _userDetailsHydrationById[userId] = future;
    return future;
  }

  Future<void> refreshChannels({bool silent = false}) async {
    await _wrap(
      () async {
        final previousById = <int, ChannelModel>{
          for (final channel in _channels) channel.channelId: channel,
        };
        final fetched = await _channelRepository.readUserChannels(
          filter: 'joined',
        );
        _channels = fetched
            .map((channel) {
              final previous = previousById[channel.channelId];
              final hasDescription =
                  channel.description?.trim().isNotEmpty == true;
              if (hasDescription || previous == null) return channel;
              return channel.copyWith(description: previous.description);
            })
            .toList(growable: false);
        if (_selectedChannel != null) {
          final match = _channels.where(
            (it) => it.channelId == _selectedChannel!.channelId,
          );
          if (match.isEmpty) {
            _selectedChannel = null;
            _messages = const [];
            _channelMembers = const [];
          } else {
            _selectedChannel = match.first;
          }
        }
        _publicGroupsByUserFuture.clear();
      },
      silent: silent,
      fallbackMessage: 'Impossible de charger les channels',
    );
  }

  Future<void> refreshPublicChannels({
    String filter = 'all',
    bool silent = false,
  }) async {
    final normalizedFilter = _normalizePublicChannelFilter(filter);
    _lastPublicChannelsFilter = normalizedFilter;
    await _wrap(
      () async {
        _publicChannels = await loadJoinDirectoryChannels(
          filter: normalizedFilter,
        );
        _publicGroupsByUserFuture.clear();
      },
      silent: silent,
      fallbackMessage: 'Impossible de charger les channels publics',
    );
  }

  Future<List<ChannelModel>> loadJoinDirectoryChannels({
    String filter = 'all',
  }) async {
    final normalizedFilter = _normalizePublicChannelFilter(filter);
    final fetched = await _channelRepository.readUserChannels(
      filter: normalizedFilter,
    );
    if (normalizedFilter == 'discover') {
      return _buildDiscoverTopChannels(fetched);
    }
    if (normalizedFilter == 'joined') {
      return _excludePrivateDmChannels(fetched);
    }
    return fetched;
  }

  Future<List<ChannelModel>> publicGroupsForUser(
    int userId, {
    bool forceRefresh = false,
  }) {
    if (userId <= 0) return Future.value(const <ChannelModel>[]);
    if (forceRefresh || !_publicGroupsByUserFuture.containsKey(userId)) {
      _publicGroupsByUserFuture[userId] = _fetchPublicGroupsForUser(userId);
    }
    return _publicGroupsByUserFuture[userId]!;
  }

  Future<List<ChannelModel>> _fetchPublicGroupsForUser(int userId) async {
    final currentUserId = _authProvider.user?.id;
    if (currentUserId != null && currentUserId == userId) {
      return _channels
          .where(
            (channel) =>
                channel.channelType.trim().toUpperCase() == 'GROUP' &&
                channel.visibility.trim().toUpperCase() == 'PUBLIC',
          )
          .toList(growable: false);
    }

    final fetched = await loadJoinDirectoryChannels(filter: 'all');
    final byId = <int, ChannelModel>{};

    for (final channel in fetched) {
      final isPublicGroup =
          channel.channelType.trim().toUpperCase() == 'GROUP' &&
          channel.visibility.trim().toUpperCase() == 'PUBLIC';
      if (!isPublicGroup) continue;
      byId[channel.channelId] = channel;
    }

    for (final channel in _channels) {
      final isPublicGroup =
          channel.channelType.trim().toUpperCase() == 'GROUP' &&
          channel.visibility.trim().toUpperCase() == 'PUBLIC';
      if (!isPublicGroup) continue;
      byId[channel.channelId] = byId[channel.channelId] ?? channel;
    }

    final matches = <ChannelModel>[];
    for (final channel in byId.values) {
      if (channel.createdBy == userId) {
        matches.add(channel);
        continue;
      }
      try {
        final members = await _channelRepository.readChannelUsers(
          channel.channelId,
        );
        final isMember = members.any((member) => member.id == userId);
        if (isMember) {
          matches.add(channel);
        }
      } catch (_) {
        // Ignore individual channel lookup failures.
      }
    }

    matches.sort(
      (a, b) =>
          a.name.trim().toLowerCase().compareTo(b.name.trim().toLowerCase()),
    );
    return matches;
  }

  Future<void> refreshShop({bool silent = false}) async {
    await _wrap(
      () async {
        _shopItems = await _shopRepository.readAll();
      },
      silent: silent,
      fallbackMessage: 'Impossible de charger la boutique',
    );
  }

  Future<void> refreshInventory({bool silent = false}) async {
    await _wrap(
      () async {
        _inventoryItems = await _inventoryRepository.readAll();
      },
      silent: silent,
      fallbackMessage: 'Impossible de charger l\'inventaire',
    );
  }

  Future<void> refreshInvoices({bool silent = false}) async {
    await _wrap(
      () async {
        _invoices = await _invoiceRepository.readAll();
      },
      silent: silent,
      fallbackMessage: 'Impossible de charger les factures',
    );
  }

}
