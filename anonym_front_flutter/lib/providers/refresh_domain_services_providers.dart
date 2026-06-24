part of 'app_providers.dart';

class _SocialRefreshDomainService {
  _SocialRefreshDomainService(this._app);

  final AppProvider _app;

  Future<void> refreshFriends({bool silent = false}) async {
    await _app._wrap(
      () async {
        _app._friends = await _app._friendsRepository.readAll();
        for (final friend in _app._friends) {
          final details = friend.friendDetails;
          if (details == null || details.id <= 0) continue;
          _app._presenceByUserId[details.id] = PresenceUtils.normalize(
            details.presenceStatus,
          );
        }
        _app._markPresenceStateChanged();
      },
      silent: silent,
      fallbackMessage: 'Impossible de charger les amis',
    );
  }

  Future<void> refreshFriendRequests({bool silent = false}) async {
    await _app._wrap(
      () async {
        final responses = await Future.wait([
          _app._friendsRepository.readIncomingRequests(),
          _app._friendsRepository.readOutgoingRequests(),
        ]);
        _app._incomingFriendRequests = responses[0];
        _app._outgoingFriendRequests = responses[1];
        for (final request in _app._incomingFriendRequests) {
          final details = request.friendDetails;
          if (details == null || details.id <= 0) continue;
          _app._presenceByUserId[details.id] = PresenceUtils.normalize(
            details.presenceStatus,
          );
        }
        for (final request in _app._outgoingFriendRequests) {
          final details = request.friendDetails;
          if (details == null || details.id <= 0) continue;
          _app._presenceByUserId[details.id] = PresenceUtils.normalize(
            details.presenceStatus,
          );
        }
        _app._markPresenceStateChanged();
      },
      silent: silent,
      fallbackMessage: 'Impossible de charger les demandes d\'amis',
    );
  }

  Future<void> refreshBlockedUsers({bool silent = false}) async {
    await _app._wrap(
      () async {
        final blockedFromApi = await _app._friendsRepository.readBlockedUsers();
        final blockedFromFriends = _app._friends
            .where((friend) => _app._isBlockedFriendStatus(friend.status))
            .map((friend) => friend.friendDetails)
            .whereType<UserModel>();
        final byId = <int, UserModel>{
          for (final user in blockedFromApi) user.id: user,
        };
        for (final user in blockedFromFriends) {
          if (user.id > 0) byId[user.id] = user;
        }
        _app._blockedUsers = byId.values.toList(growable: false);
        for (final user in _app._blockedUsers) {
          if (user.id <= 0) continue;
          _app._presenceByUserId[user.id] = PresenceUtils.normalize(
            user.presenceStatus,
          );
        }
        _app._markPresenceStateChanged();
      },
      silent: silent,
      fallbackMessage: 'Impossible de charger les utilisateurs bloques',
    );
  }

  Future<void> refreshUsers({bool silent = false}) async {
    await _app._wrap(
      () async {
        _app._allUsers = await _app._accountRepository.readAllUsers();
        for (final user in _app._allUsers) {
          if (user.id <= 0) continue;
          _app._presenceByUserId[user.id] = PresenceUtils.normalize(
            user.presenceStatus,
          );
        }
        _app._markPresenceStateChanged();
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
      final existing = _app.userById(userId);
      if (existing != null && existing.inventories.isNotEmpty) {
        return existing;
      }
      final inflight = _app._userDetailsHydrationById[userId];
      if (inflight != null) return inflight;
    }

    final future = () async {
      try {
        final fetched = await _app._accountRepository.readUserById(userId);
        _app._upsertUserInAllUsers(fetched);
        return fetched;
      } catch (_) {
        return null;
      } finally {
        _app._userDetailsHydrationById.remove(userId);
      }
    }();

    _app._userDetailsHydrationById[userId] = future;
    return future;
  }
}

class _ChannelsRefreshDomainService {
  _ChannelsRefreshDomainService(this._app);

  final AppProvider _app;

  Future<void> refreshChannels({bool silent = false}) async {
    await _app._wrap(
      () async {
        final previousById = <int, ChannelModel>{
          for (final channel in _app._channels) channel.channelId: channel,
        };
        final fetched = await _app._channelRepository.readUserChannels(
          filter: 'joined',
        );
        _app._channels = fetched
            .map((channel) {
              final previous = previousById[channel.channelId];
              final hasDescription =
                  channel.description?.trim().isNotEmpty == true;
              if (hasDescription || previous == null) return channel;
              return channel.copyWith(description: previous.description);
            })
            .toList(growable: false);
        if (_app._selectedChannel != null) {
          final match = _app._channels.where(
            (it) => it.channelId == _app._selectedChannel!.channelId,
          );
          if (match.isEmpty) {
            _app._selectedChannel = null;
            _app._messages = const [];
            _app._channelMembers = const [];
          } else {
            _app._selectedChannel = match.first;
          }
        }
        _app._publicGroupsByUserFuture.clear();
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
    _app._lastPublicChannelsFilter = normalizedFilter;
    await _app._wrap(
      () async {
        _app._publicChannels = await loadJoinDirectoryChannels(
          filter: normalizedFilter,
        );
        _app._publicGroupsByUserFuture.clear();
      },
      silent: silent,
      fallbackMessage: 'Impossible de charger les channels publics',
    );
  }

  Future<List<ChannelModel>> loadJoinDirectoryChannels({
    String filter = 'all',
  }) async {
    final normalizedFilter = _normalizePublicChannelFilter(filter);
    final fetched = await _app._channelRepository.readUserChannels(
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
    if (forceRefresh || !_app._publicGroupsByUserFuture.containsKey(userId)) {
      _app._publicGroupsByUserFuture[userId] = _fetchPublicGroupsForUser(
        userId,
      );
    }
    return _app._publicGroupsByUserFuture[userId]!;
  }

  Future<List<ChannelModel>> _fetchPublicGroupsForUser(int userId) async {
    final currentUserId = _app._authProvider.user?.id;
    if (currentUserId != null && currentUserId == userId) {
      return _app._channels
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

    for (final channel in _app._channels) {
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
        final members = await _app._channelRepository.readChannelUsers(
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
}

class _CommerceRefreshDomainService {
  _CommerceRefreshDomainService(this._app);

  final AppProvider _app;

  Future<void> refreshShop({bool silent = false}) async {
    await _app._wrap(
      () async {
        _app._shopItems = await _app._shopRepository.readAll();
      },
      silent: silent,
      fallbackMessage: 'Impossible de charger la boutique',
    );
  }

  Future<void> refreshInventory({bool silent = false}) async {
    await _app._wrap(
      () async {
        _app._inventoryItems = await _app._inventoryRepository.readAll();
      },
      silent: silent,
      fallbackMessage: 'Impossible de charger l\'inventaire',
    );
  }

  Future<void> refreshInvoices({bool silent = false}) async {
    await _app._wrap(
      () async {
        _app._invoices = await _app._invoiceRepository.readAll();
      },
      silent: silent,
      fallbackMessage: 'Impossible de charger les factures',
    );
  }
}
