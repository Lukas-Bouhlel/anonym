part of '../screens/home_screen.dart';

class _HomeMap extends StatefulWidget {
  const _HomeMap({super.key});

  @override
  State<_HomeMap> createState() => _HomeMapState();
}

class _HomeMapState extends State<_HomeMap> {
  late final HomeLocationController _locationController;
  late final VoidCallback _controllerListener;

  @override
  void initState() {
    super.initState();
    final presence = context.read<PresenceProvider>();
    _locationController = HomeLocationController(
      publishMyLiveLocation:
          ({
            required double latitude,
            required double longitude,
            double? accuracy,
          }) {
            presence.publishMyLiveLocation(
              latitude: latitude,
              longitude: longitude,
              accuracy: accuracy,
            );
          },
      stopMyLiveLocationSharing: presence.stopMyLiveLocationSharing,
      activeFrameUrlForUser: presence.activeFrameUrlForUser,
      logger: (message) => AppLogger.debug(message),
    );
    _controllerListener = () {
      if (!mounted) return;
      setState(() {});
    };
    _locationController.addListener(_controllerListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_locationController.startLocationTracking());
    });
  }

  @override
  void dispose() {
    _locationController.removeListener(_controllerListener);
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liveLocations = context
        .select<PresenceProvider, List<LiveUserLocationModel>>(
          (presence) => presence.liveUserLocations,
        );
    final selfUserId = context.select<AuthProvider, int?>(
      (auth) => auth.user?.id,
    );
    final selfUsername = context.select<AuthProvider, String>(
      (auth) => auth.user?.username ?? 'moi',
    );
    final selfAvatar = context.select<AuthProvider, String?>(
      (auth) => auth.user?.avatar,
    );
    final hydratedLocations = _locationController.buildHydratedLocations(
      liveLocations: liveLocations,
      selfUserId: selfUserId,
      selfUsername: selfUsername,
      selfAvatar: selfAvatar,
    );

    return AnonymMapView(
      locations: hydratedLocations,
      selfUserId: selfUserId,
      cameraTarget: _locationController.cameraTarget,
    );
  }

  Future<void> centerOnMyCurrentLocation() async {
    await _locationController.centerOnMyCurrentLocation();
  }
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
          tooltip: 'Rafraichir',
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
