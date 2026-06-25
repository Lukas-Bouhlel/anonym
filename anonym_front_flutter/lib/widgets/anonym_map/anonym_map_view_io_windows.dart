part of 'anonym_map_view_io.dart';

class _WindowsMapboxGlMap extends StatefulWidget {
  const _WindowsMapboxGlMap({
    required this.locations,
    required this.selfUserId,
    required this.cameraTarget,
  });

  final List<LiveUserLocationModel> locations;
  final int? selfUserId;
  final AnonymMapCameraTarget? cameraTarget;

  @override
  State<_WindowsMapboxGlMap> createState() => _WindowsMapboxGlMapState();
}

class _WindowsMapboxGlMapState extends State<_WindowsMapboxGlMap> {
  wv.WebviewController? _controller;
  StreamSubscription<dynamic>? _messageSubscription;
  Object? _initializationError;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeWebview());
  }

  @override
  void didUpdateWidget(covariant _WindowsMapboxGlMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    unawaited(_sendStateToWebview());
  }

  @override
  void dispose() {
    unawaited(_messageSubscription?.cancel());
    final controller = _controller;
    if (controller != null) {
      unawaited(controller.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_initializationError != null) {
      return _MapUnavailableMessage(
        message: 'Mapbox GL Windows indisponible.',
        detail: 'WebView2 doit etre installe sur Windows.',
      );
    }

    if (controller == null || !controller.value.isInitialized) {
      return const _MapLoadingMessage();
    }

    return wv.Webview(
      controller,
      permissionRequested: (url, kind, isUserInitiated) =>
          wv.WebviewPermissionDecision.deny,
    );
  }

  Future<void> _initializeWebview() async {
    final controller = wv.WebviewController();
    try {
      await controller.initialize();
      await controller.setBackgroundColor(AppColors.c393566);
      await controller.setPopupWindowPolicy(wv.WebviewPopupWindowPolicy.deny);
      _messageSubscription = controller.webMessage.listen((message) {
        final decoded = _decodeWebviewMessage(message);
        if (decoded is Map && decoded['type'] == 'ready') {
          _mapReady = true;
          unawaited(_sendStateToWebview());
        }
      });
      await controller.loadStringContent(
        _windowsMapHtml(AppConfig.mapboxAccessToken),
      );
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _initializationError = error;
      });
    }
  }

  Object? _decodeWebviewMessage(dynamic message) {
    if (message is String) {
      try {
        return jsonDecode(message);
      } catch (_) {
        return null;
      }
    }
    return message;
  }

  Future<void> _sendStateToWebview() async {
    if (!_mapReady) return;
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final markers = buildAnonymMapMarkers(widget.locations, widget.selfUserId);
    final message = {
      'type': 'state',
      'markers': markers.map((marker) => marker.toJson()).toList(),
      'camera': widget.cameraTarget?.toJson(),
    };
    final first = markers.isEmpty ? null : markers.first;
    AppLogger.debug(
      '[ANONYM_MAP][windows][send] markers=${markers.length} '
      'first=${first == null ? '-' : '${first.latitude.toStringAsFixed(6)},${first.longitude.toStringAsFixed(6)}'} '
      'camera=${widget.cameraTarget == null ? '-' : '${widget.cameraTarget!.latitude.toStringAsFixed(6)},${widget.cameraTarget!.longitude.toStringAsFixed(6)}'}',
    );
    try {
      await controller.postWebMessage(jsonEncode(message));
    } catch (_) {
      // The WebView can be closing while Flutter is disposing the page.
    }
  }
}
