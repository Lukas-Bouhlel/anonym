part of 'app_providers.dart';

class _AppProviderPresenceService {
  _AppProviderPresenceService(this._app);

  final AppProvider _app;

  bool isLocationPayloadValid(LiveUserLocationModel value) {
    if (value.userId <= 0) return false;
    if (value.latitude < -90 || value.latitude > 90) return false;
    if (value.longitude < -180 || value.longitude > 180) return false;
    return true;
  }

  Set<int> visibleLocationUserIds() {
    final visible = <int>{};
    final meId = _app._authProvider.user?.id;
    if (meId != null && meId > 0) {
      visible.add(meId);
    }
    for (final friend in _app._friends) {
      if (!isActiveFriendStatus(friend.status)) continue;
      if (friend.friendId <= 0) continue;
      visible.add(friend.friendId);
    }
    return visible;
  }

  bool shouldDisplayLocationForUser(int userId) {
    if (userId <= 0) return false;
    return visibleLocationUserIds().contains(userId);
  }

  bool pruneHiddenLiveLocations() {
    if (_app._liveLocationsByUserId.isEmpty) return false;
    final visibleIds = visibleLocationUserIds();
    final removedIds = _app._liveLocationsByUserId.keys
        .where((userId) => !visibleIds.contains(userId))
        .toList(growable: false);
    if (removedIds.isEmpty) return false;
    for (final userId in removedIds) {
      _app._liveLocationsByUserId.remove(userId);
    }
    _app._markPresenceStateChanged();
    return true;
  }

  double distanceInMeters(double lat1, double lon1, double lat2, double lon2) {
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

  bool isActiveFriendStatus(String status) {
    final normalized = status.trim().toUpperCase();
    return normalized == 'ACTIVE';
  }

  bool isBlockedFriendStatus(String status) {
    final normalized = status.trim().toUpperCase();
    return normalized == 'BLOCKED' || normalized == 'BLOQUED';
  }

  double _toRadians(double deg) => deg * 0.017453292519943295;
}
