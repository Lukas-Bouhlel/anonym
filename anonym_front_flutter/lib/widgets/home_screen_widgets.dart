part of '../screens/home_screen.dart';

class _HomeMap extends StatefulWidget {
  const _HomeMap({super.key});

  @override
  State<_HomeMap> createState() => _HomeMapState();
}

class _HomeMapState extends State<_HomeMap> {
  static const double _minimumStableMoveMeters = 18;
  static const double _maximumRejectedAccuracyMeters = 150;
  static const Duration _maxSilenceBeforeForceAccept = Duration(seconds: 20);

  StreamSubscription<geo.Position>? _positionSubscription;
  Timer? _positionPollingTimer;
  geo.Position? _lastKnownLocalPosition;
  DateTime? _lastAcceptedPositionAt;
  AnonymMapCameraTarget? _cameraTarget;
  bool _cameraCenteredOnFirstFix = false;
  bool _locationStreamStarted = false;
  int _cameraRevision = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_startLocationTracking());
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _positionPollingTimer?.cancel();
    _positionPollingTimer = null;
    try {
      context.read<AppProvider>().stopMyLiveLocationSharing();
    } catch (_) {
      // Provider might already be disposed during app teardown.
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final liveLocations = app.liveUserLocations;
    final selfUserId = context.select<AuthProvider, int?>(
      (auth) => auth.user?.id,
    );
    final selfUsername = context.select<AuthProvider, String>(
      (auth) => auth.user?.username ?? 'moi',
    );
    final selfAvatar = context.select<AuthProvider, String?>(
      (auth) => auth.user?.avatar,
    );
    final selfFrameUrl = selfUserId == null
        ? null
        : app.activeFrameUrlForUser(selfUserId);

    final locationsWithLocalFallback = _mergeLocalMarkerFallback(
      locations: liveLocations,
      selfUserId: selfUserId,
      selfUsername: selfUsername,
      selfAvatar: selfAvatar,
      selfFrameUrl: selfFrameUrl,
    );
    final hydratedLocations = _hydrateLocationsWithProfileDecorations(
      app: app,
      locations: locationsWithLocalFallback,
      selfUserId: selfUserId,
      selfAvatar: selfAvatar,
      selfFrameUrl: selfFrameUrl,
    );

    return AnonymMapView(
      locations: hydratedLocations,
      selfUserId: selfUserId,
      cameraTarget: _cameraTarget,
    );
  }

  Future<void> centerOnMyCurrentLocation() async {
    if (!mounted) return;
    final app = context.read<AppProvider>();
    final cached = _lastKnownLocalPosition;
    if (cached != null) {
      debugPrint(
        '[ANONYM_GEO][recenter] cached lat=${_fmt(cached.latitude)} lon=${_fmt(cached.longitude)}',
      );
      _centerCamera(cached.latitude, cached.longitude);
    }

    try {
      final current = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.best,
        ),
      );
      debugPrint(
        '[ANONYM_GEO][recenter] fresh lat=${_fmt(current.latitude)} lon=${_fmt(current.longitude)} acc=${current.accuracy.toStringAsFixed(1)}m',
      );
      _publishPosition(app, current, forceCameraCenter: true);
    } catch (_) {
      // Keep last centered location if current fix is unavailable.
      debugPrint('[ANONYM_GEO][recenter] failed to fetch current position');
    }
  }

  Future<void> _startLocationTracking() async {
    if (_locationStreamStarted) return;
    _locationStreamStarted = true;

    final permissionGranted = await _ensureLocationPermission();
    if (!permissionGranted || !mounted) {
      debugPrint('[ANONYM_GEO][start] permission denied or widget unmounted');
      _locationStreamStarted = false;
      return;
    }
    debugPrint('[ANONYM_GEO][start] permission granted');

    final app = context.read<AppProvider>();
    try {
      final lastKnown = await geo.Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        _publishPosition(app, lastKnown);
      }

      final initial = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );
      _publishPosition(app, initial);
    } catch (_) {
      // Ignore initial GPS failures, stream updates may still succeed.
    }

    if (_shouldUsePollingLocationUpdates) {
      debugPrint('[ANONYM_GEO][start] updates mode=polling (windows)');
      _positionPollingTimer?.cancel();
      _positionPollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        unawaited(_pollCurrentPosition(app));
      });
      return;
    }

    debugPrint('[ANONYM_GEO][start] updates mode=stream');
    _positionSubscription?.cancel();
    _positionSubscription = geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.best,
        distanceFilter: 8,
      ),
    ).listen((position) => _publishPosition(app, position), onError: (_) {});
  }

  Future<bool> _ensureLocationPermission() async {
    try {
      final serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      var permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
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

  bool get _shouldUsePollingLocationUpdates {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
  }

  Future<void> _pollCurrentPosition(AppProvider app) async {
    if (!mounted) return;
    try {
      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.best,
        ),
      );
      _publishPosition(app, position);
    } catch (_) {
      // Keep trying on next tick.
    }
  }

  void _publishPosition(
    AppProvider app,
    geo.Position position, {
    bool forceCameraCenter = false,
  }) {
    if (!mounted) return;

    final previous = _lastKnownLocalPosition;
    final accuracy = position.accuracy.abs();
    final distanceFromPrevious = previous == null
        ? null
        : geo.Geolocator.distanceBetween(
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

    debugPrint(
      '[ANONYM_GEO][raw] lat=${_fmt(position.latitude)} lon=${_fmt(position.longitude)} '
      'acc=${accuracy.toStringAsFixed(1)}m '
      'dist=${distanceFromPrevious?.toStringAsFixed(1) ?? '-'}m '
      'threshold=${dynamicThreshold.toStringAsFixed(1)}m '
      'forceCenter=$forceCameraCenter',
    );

    if (shouldReject) {
      if (rejectedByAccuracy) {
        debugPrint(
          '[ANONYM_GEO][reject] accuracy too low: ${accuracy.toStringAsFixed(1)}m > ${_maximumRejectedAccuracyMeters.toStringAsFixed(1)}m',
        );
      } else {
        debugPrint(
          '[ANONYM_GEO][reject] jitter filtered: dist=${distanceFromPrevious?.toStringAsFixed(1)}m < ${dynamicThreshold.toStringAsFixed(1)}m',
        );
      }
      if (forceCameraCenter) {
        final target = previous;
        _centerCamera(target.latitude, target.longitude);
      }
      return;
    }

    debugPrint(
      '[ANONYM_GEO][accept] lat=${_fmt(position.latitude)} lon=${_fmt(position.longitude)}',
    );
    _lastKnownLocalPosition = position;
    _lastAcceptedPositionAt = now;

    app.publishMyLiveLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
    );

    if (forceCameraCenter) {
      _cameraCenteredOnFirstFix = true;
      _centerCamera(position.latitude, position.longitude);
      return;
    }

    if (_cameraCenteredOnFirstFix) return;
    _cameraCenteredOnFirstFix = true;
    _centerCamera(position.latitude, position.longitude);
  }

  void _centerCamera(double latitude, double longitude) {
    if (!mounted) return;
    debugPrint(
      '[ANONYM_GEO][camera] center lat=${_fmt(latitude)} lon=${_fmt(longitude)} rev=${_cameraRevision + 1}',
    );
    setState(() {
      _cameraRevision += 1;
      _cameraTarget = AnonymMapCameraTarget(
        latitude: latitude,
        longitude: longitude,
        revision: _cameraRevision,
      );
    });
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
      debugPrint(
        '[ANONYM_GEO][marker] add local marker userId=$effectiveUserId lat=${_fmt(local.latitude)} lon=${_fmt(local.longitude)}',
      );
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

    debugPrint(
      '[ANONYM_GEO][marker] update local marker userId=$effectiveUserId lat=${_fmt(local.latitude)} lon=${_fmt(local.longitude)}',
    );
    final next = [...locations];
    next[index] = updated;
    return next;
  }

  List<LiveUserLocationModel> _hydrateLocationsWithProfileDecorations({
    required AppProvider app,
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
          (isSelf ? selfFrameUrl : app.activeFrameUrlForUser(item.userId));

      if (resolvedAvatar == item.avatar && resolvedFrame == item.frameUrl) {
        next.add(item);
        continue;
      }

      mutated = true;
      next.add(item.copyWith(avatar: resolvedAvatar, frameUrl: resolvedFrame));
    }

    return mutated ? next : locations;
  }

  String _fmt(double value) => value.toStringAsFixed(6);
}

class _MapboxStyleControlGroup extends StatelessWidget {
  const _MapboxStyleControlGroup({
    required this.onLocatePressed,
    required this.onRefreshPressed,
  });

  final VoidCallback onLocatePressed;
  final VoidCallback onRefreshPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MapboxStyleControlButton(
          tooltip: 'Ma position',
          icon: Icons.my_location_rounded,
          onPressed: onLocatePressed,
        ),
        const SizedBox(height: 10),
        _MapboxStyleControlButton(
          tooltip: 'Rafraîchir',
          icon: Icons.refresh_rounded,
          onPressed: onRefreshPressed,
        ),
      ],
    );
  }
}

class _MapboxStyleControlButton extends StatelessWidget {
  const _MapboxStyleControlButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.textPrimary.withValues(alpha: 0.80),
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.24),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Center(
              child: Icon(icon, size: 20, color: AppColors.whiteColor),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.c292929.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cFCFAFE.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Text(
          message,
          style: const TextStyle(
            color: AppColors.cFCFAFE,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
