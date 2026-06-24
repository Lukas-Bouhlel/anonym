import 'package:flutter/foundation.dart';

import '../models/live_user_location_model.dart';
import 'app_providers.dart';

/// Domain provider for presence and live location signals.
class PresenceProvider extends ChangeNotifier {
  PresenceProvider(this._app) {
    _listener = notifyListeners;
    _app.presenceListenable.addListener(_listener);
  }

  final AppProvider _app;
  late final VoidCallback _listener;

  List<LiveUserLocationModel> get liveUserLocations => _app.liveUserLocations;
  int get realtimeStatsVersion => _app.realtimeStatsVersion;

  String? activeFrameUrlForUser(int userId) =>
      _app.activeFrameUrlForUser(userId);

  String presenceStatusForUser(int userId, {bool isCurrentUser = false}) {
    return _app.presenceStatusForUser(userId, isCurrentUser: isCurrentUser);
  }

  String presenceLabelForUser(int userId, {bool isCurrentUser = false}) {
    return _app.presenceLabelForUser(userId, isCurrentUser: isCurrentUser);
  }

  Future<void> updateMyPresenceStatus(String presenceStatus) {
    return _app.updateMyPresenceStatus(presenceStatus);
  }

  void publishMyLiveLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
  }) {
    _app.publishMyLiveLocation(
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
    );
  }

  void stopMyLiveLocationSharing() => _app.stopMyLiveLocationSharing();

  @override
  void dispose() {
    _app.presenceListenable.removeListener(_listener);
    super.dispose();
  }
}
