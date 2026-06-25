import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;

import '../models/live_user_location_model.dart';
import '../widgets/anonym_map/anonym_map_data.dart';

typedef PublishLiveLocationCallback =
    void Function({
      required double latitude,
      required double longitude,
      double? accuracy,
    });
typedef StopLiveLocationSharingCallback = void Function();
typedef ActiveFrameUrlResolver = String? Function(int userId);

/// Geolocation adapter used by [HomeLocationController].
class HomeGeoService {
  const HomeGeoService();

  Future<bool> isLocationServiceEnabled() {
    return geo.Geolocator.isLocationServiceEnabled();
  }

  Future<geo.LocationPermission> checkPermission() {
    return geo.Geolocator.checkPermission();
  }

  Future<geo.LocationPermission> requestPermission() {
    return geo.Geolocator.requestPermission();
  }

  Future<geo.Position?> getLastKnownPosition() {
    return geo.Geolocator.getLastKnownPosition();
  }

  Future<geo.Position> getCurrentPosition({
    required geo.LocationSettings locationSettings,
  }) {
    return geo.Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );
  }

  Stream<geo.Position> getPositionStream({
    required geo.LocationSettings locationSettings,
  }) {
    return geo.Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  double distanceBetween(double lat1, double lon1, double lat2, double lon2) {
    return geo.Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
}

/// Dedicated controller that owns map/geolocation runtime behavior for home UI.
class HomeLocationController extends ChangeNotifier {
  HomeLocationController({
    required this.publishMyLiveLocation,
    required this.stopMyLiveLocationSharing,
    required this.activeFrameUrlForUser,
    HomeGeoService? geoService,
    bool? forcePollingLocationUpdates,
    void Function(String message)? logger,
  }) : _geoService = geoService ?? const HomeGeoService(),
       _forcePollingLocationUpdates = forcePollingLocationUpdates,
       _logger = logger;

  static const double _minimumStableMoveMeters = 18;
  static const double _maximumRejectedAccuracyMeters = 150;
  static const Duration _maxSilenceBeforeForceAccept = Duration(seconds: 20);

  final PublishLiveLocationCallback publishMyLiveLocation;
  final StopLiveLocationSharingCallback stopMyLiveLocationSharing;
  final ActiveFrameUrlResolver activeFrameUrlForUser;

  final HomeGeoService _geoService;
  final bool? _forcePollingLocationUpdates;
  final void Function(String message)? _logger;

  StreamSubscription<geo.Position>? _positionSubscription;
  Timer? _positionPollingTimer;
  geo.Position? _lastKnownLocalPosition;
  DateTime? _lastAcceptedPositionAt;
  AnonymMapCameraTarget? _cameraTarget;
  bool _cameraCenteredOnFirstFix = false;
  bool _locationStreamStarted = false;
  int _cameraRevision = 0;

  AnonymMapCameraTarget? get cameraTarget => _cameraTarget;

  bool get _shouldUsePollingLocationUpdates {
    return _forcePollingLocationUpdates ??
        (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows);
  }

  Future<void> startLocationTracking() async {
    if (_locationStreamStarted) return;
    _locationStreamStarted = true;

    final permissionGranted = await _ensureLocationPermission();
    if (!permissionGranted) {
      _log('[ANONYM_GEO][start] permission denied');
      _locationStreamStarted = false;
      return;
    }
    _log('[ANONYM_GEO][start] permission granted');

    try {
      final lastKnown = await _geoService.getLastKnownPosition();
      if (lastKnown != null) {
        handleIncomingPosition(lastKnown);
      }

      final initial = await _geoService.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );
      handleIncomingPosition(initial);
    } catch (_) {
      // Keep initial location lookup best-effort.
    }

    if (_shouldUsePollingLocationUpdates) {
      _log('[ANONYM_GEO][start] updates mode=polling (windows)');
      _positionPollingTimer?.cancel();
      _positionPollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        unawaited(_pollCurrentPosition());
      });
      return;
    }

    _log('[ANONYM_GEO][start] updates mode=stream');
    _positionSubscription?.cancel();
    _positionSubscription = _geoService
        .getPositionStream(
          locationSettings: const geo.LocationSettings(
            accuracy: geo.LocationAccuracy.best,
            distanceFilter: 8,
          ),
        )
        .listen(handleIncomingPosition, onError: (_) {});
  }

  Future<void> centerOnMyCurrentLocation() async {
    final cached = _lastKnownLocalPosition;
    if (cached != null) {
      _log('[ANONYM_GEO][recenter] using cached position');
      _centerCamera(cached.latitude, cached.longitude);
    }

    try {
      final current = await _geoService.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.best,
        ),
      );
      _log(
        '[ANONYM_GEO][recenter] fresh fix accuracy=${current.accuracy.toStringAsFixed(1)}m',
      );
      handleIncomingPosition(current, forceCameraCenter: true);
    } catch (_) {
      _log('[ANONYM_GEO][recenter] failed to fetch current position');
    }
  }

  void handleIncomingPosition(
    geo.Position position, {
    bool forceCameraCenter = false,
  }) {
    final previous = _lastKnownLocalPosition;
    final accuracy = position.accuracy.abs();
    final distanceFromPrevious = previous == null
        ? null
        : _geoService.distanceBetween(
            previous.latitude,
            previous.longitude,
            position.latitude,
            position.longitude,
          );
    final dynamicThreshold = (accuracy * 0.65).clamp(
      _shouldUsePollingLocationUpdates ? 4.0 : _minimumStableMoveMeters,
      _shouldUsePollingLocationUpdates ? 12.0 : 40.0,
    );
    final now = DateTime.now();
    final elapsedSinceLastAccept = _lastAcceptedPositionAt == null
        ? null
        : now.difference(_lastAcceptedPositionAt!);
    final forceAcceptBySilence =
        elapsedSinceLastAccept != null &&
        elapsedSinceLastAccept >= _maxSilenceBeforeForceAccept;
    final rejectedByAccuracy =
        previous != null &&
        accuracy.isFinite &&
        accuracy > _maximumRejectedAccuracyMeters;
    final rejectedByDistance =
        previous != null &&
        !rejectedByAccuracy &&
        distanceFromPrevious != null &&
        distanceFromPrevious < dynamicThreshold;
    final shouldReject =
        (rejectedByAccuracy || rejectedByDistance) && !forceAcceptBySilence;

    _log(
      '[ANONYM_GEO][raw] acc=${accuracy.toStringAsFixed(1)}m '
      'dist=${distanceFromPrevious?.toStringAsFixed(1) ?? '-'}m '
      'threshold=${dynamicThreshold.toStringAsFixed(1)}m '
      'forceCenter=$forceCameraCenter',
    );

    if (shouldReject) {
      if (rejectedByAccuracy) {
        _log(
          '[ANONYM_GEO][reject] accuracy too low: ${accuracy.toStringAsFixed(1)}m > ${_maximumRejectedAccuracyMeters.toStringAsFixed(1)}m',
        );
      } else {
        _log(
          '[ANONYM_GEO][reject] jitter filtered: dist=${distanceFromPrevious?.toStringAsFixed(1)}m < ${dynamicThreshold.toStringAsFixed(1)}m',
        );
      }
      if (forceCameraCenter) {
        _centerCamera(previous.latitude, previous.longitude);
      }
      return;
    }

    _log('[ANONYM_GEO][accept] position accepted');
    _lastKnownLocalPosition = position;
    _lastAcceptedPositionAt = now;
    publishMyLiveLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
    );

    if (forceCameraCenter) {
      _cameraCenteredOnFirstFix = true;
      _centerCamera(position.latitude, position.longitude);
      return;
    }

    if (_cameraCenteredOnFirstFix) {
      notifyListeners();
      return;
    }
    _cameraCenteredOnFirstFix = true;
    _centerCamera(position.latitude, position.longitude);
  }

  List<LiveUserLocationModel> buildHydratedLocations({
    required List<LiveUserLocationModel> liveLocations,
    required int? selfUserId,
    required String selfUsername,
    required String? selfAvatar,
  }) {
    final selfFrameUrl = selfUserId == null
        ? null
        : activeFrameUrlForUser(selfUserId);
    final withLocalFallback = _mergeLocalMarkerFallback(
      locations: liveLocations,
      selfUserId: selfUserId,
      selfUsername: selfUsername,
      selfAvatar: selfAvatar,
      selfFrameUrl: selfFrameUrl,
    );
    return _hydrateLocationsWithProfileDecorations(
      locations: withLocalFallback,
      selfUserId: selfUserId,
      selfAvatar: selfAvatar,
      selfFrameUrl: selfFrameUrl,
    );
  }

  List<LiveUserLocationModel> _mergeLocalMarkerFallback({
    required List<LiveUserLocationModel> locations,
    required int? selfUserId,
    required String selfUsername,
    required String? selfAvatar,
    required String? selfFrameUrl,
  }) {
    final local = _lastKnownLocalPosition;
    if (local == null) return locations;

    final effectiveUserId = selfUserId ?? -1;
    final effectiveUsername = selfUsername.trim().isEmpty
        ? 'Moi'
        : selfUsername.trim();

    final localModel = LiveUserLocationModel(
      userId: effectiveUserId,
      username: effectiveUsername,
      avatar: selfAvatar,
      frameUrl: selfFrameUrl,
      latitude: local.latitude,
      longitude: local.longitude,
      updatedAt: DateTime.now().toUtc(),
    );

    final index = locations.indexWhere(
      (item) => item.userId == effectiveUserId,
    );
    if (index == -1) {
      _log('[ANONYM_GEO][marker] add local marker userId=$effectiveUserId');
      return [...locations, localModel];
    }

    final current = locations[index];
    final sameSpot =
        (current.latitude - local.latitude).abs() < 0.000001 &&
        (current.longitude - local.longitude).abs() < 0.000001;
    if (sameSpot) return locations;

    final updated = current.copyWith(
      latitude: local.latitude,
      longitude: local.longitude,
      username: current.username.isEmpty ? selfUsername : current.username,
      avatar: current.avatar ?? selfAvatar,
      frameUrl: current.frameUrl ?? selfFrameUrl,
      updatedAt: DateTime.now().toUtc(),
    );

    _log('[ANONYM_GEO][marker] update local marker userId=$effectiveUserId');
    final next = [...locations];
    next[index] = updated;
    return next;
  }

  List<LiveUserLocationModel> _hydrateLocationsWithProfileDecorations({
    required List<LiveUserLocationModel> locations,
    required int? selfUserId,
    required String? selfAvatar,
    required String? selfFrameUrl,
  }) {
    var mutated = false;
    final next = <LiveUserLocationModel>[];

    for (final item in locations) {
      final isSelf = selfUserId != null && item.userId == selfUserId;
      final resolvedAvatar = item.avatar ?? (isSelf ? selfAvatar : null);
      final resolvedFrame =
          item.frameUrl ??
          (isSelf ? selfFrameUrl : activeFrameUrlForUser(item.userId));

      if (resolvedAvatar == item.avatar && resolvedFrame == item.frameUrl) {
        next.add(item);
        continue;
      }

      mutated = true;
      next.add(item.copyWith(avatar: resolvedAvatar, frameUrl: resolvedFrame));
    }

    return mutated ? next : locations;
  }

  Future<bool> _ensureLocationPermission() async {
    try {
      final serviceEnabled = await _geoService.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      var permission = await _geoService.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await _geoService.requestPermission();
      }
      if (permission == geo.LocationPermission.denied ||
          permission == geo.LocationPermission.deniedForever) {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _pollCurrentPosition() async {
    try {
      final position = await _geoService.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.best,
        ),
      );
      handleIncomingPosition(position);
    } catch (_) {
      // Retry on next poll tick.
    }
  }

  void _centerCamera(double latitude, double longitude) {
    _log('[ANONYM_GEO][camera] center rev=${_cameraRevision + 1}');
    _cameraRevision += 1;
    _cameraTarget = AnonymMapCameraTarget(
      latitude: latitude,
      longitude: longitude,
      revision: _cameraRevision,
    );
    notifyListeners();
  }

  void _log(String message) {
    _logger?.call(message);
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _positionPollingTimer?.cancel();
    _positionPollingTimer = null;
    stopMyLiveLocationSharing();
    super.dispose();
  }
}
