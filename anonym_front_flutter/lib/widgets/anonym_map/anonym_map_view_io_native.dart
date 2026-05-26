part of 'anonym_map_view_io.dart';

class _NativeMapboxMap extends StatefulWidget {
  const _NativeMapboxMap({
    required this.locations,
    required this.selfUserId,
    required this.cameraTarget,
  });

  final List<LiveUserLocationModel> locations;
  final int? selfUserId;
  final AnonymMapCameraTarget? cameraTarget;

  @override
  State<_NativeMapboxMap> createState() => _NativeMapboxMapState();
}

class _NativeMapboxMapState extends State<_NativeMapboxMap> {
  static const double _topDownPitch = 0;
  static const double _northUpBearing = 0;

  static final _initialViewport = mb.CameraViewportState(
    center: mb.Point(coordinates: mb.Position(2.3522, 48.8566)),
    zoom: 12,
    bearing: _northUpBearing,
    pitch: _topDownPitch,
  );

  mb.MapboxMap? _mapboxMap;
  mb.PointAnnotationManager? _annotationManager;

  final Map<String, ui.Image?> _avatarImageCache = <String, ui.Image?>{};
  final Map<String, Future<ui.Image?>> _avatarInFlight =
      <String, Future<ui.Image?>>{};
  final Map<String, Uint8List> _markerBytesCache = <String, Uint8List>{};

  List<AnonymMapMarkerData> _queuedMarkers = const [];
  String _markersFingerprint = '';
  bool _renderLoopRunning = false;
  int? _lastCameraRevision;

  @override
  void initState() {
    super.initState();
    mb.MapboxOptions.setAccessToken(AppConfig.mapboxAccessToken);
  }

  @override
  void didUpdateWidget(covariant _NativeMapboxMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleMarkerRender();
    _moveToCameraTargetIfNeeded();
  }

  @override
  void dispose() {
    for (final image in _avatarImageCache.values) {
      image?.dispose();
    }
    _avatarImageCache.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return mb.MapWidget(
      key: const ValueKey('home-mapbox-native-map'),
      gestureRecognizers: {
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
      },
      styleUri: mb.MapboxStyles.STANDARD,
      viewport: _initialViewport,
      onMapCreated: _onMapCreated,
    );
  }

  Future<void> _onMapCreated(mb.MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    await _applyAnonymMapTheme(mapboxMap);
    mapboxMap.gestures.updateSettings(
      mb.GesturesSettings(
        rotateEnabled: true,
        pinchToZoomEnabled: true,
        scrollEnabled: true,
        simultaneousRotateAndPinchToZoomEnabled: true,
        pitchEnabled: false,
        scrollMode: mb.ScrollMode.HORIZONTAL_AND_VERTICAL,
        doubleTapToZoomInEnabled: true,
        doubleTouchToZoomOutEnabled: true,
        quickZoomEnabled: true,
        pinchPanEnabled: true,
      ),
    );
    mapboxMap.compass.updateSettings(
      mb.CompassSettings(
        position: mb.OrnamentPosition.TOP_RIGHT,
        marginTop: 104,
        marginRight: 16,
      ),
    );
    mapboxMap.scaleBar.updateSettings(mb.ScaleBarSettings(enabled: false));
    mapboxMap.logo.updateSettings(
      mb.LogoSettings(
        position: mb.OrnamentPosition.BOTTOM_LEFT,
        marginLeft: 16,
        marginBottom: 112,
      ),
    );
    mapboxMap.attribution.updateSettings(
      mb.AttributionSettings(
        position: mb.OrnamentPosition.BOTTOM_RIGHT,
        marginRight: 16,
        marginBottom: 112,
      ),
    );

    _annotationManager = await mapboxMap.annotations
        .createPointAnnotationManager();
    await _annotationManager?.setIconAllowOverlap(true);
    await _annotationManager?.setTextAllowOverlap(true);

    _scheduleMarkerRender(force: true);
    _moveToCameraTargetIfNeeded();
  }

  Future<void> _applyAnonymMapTheme(mb.MapboxMap mapboxMap) async {
    try {
      await mapboxMap.style.setStyleImportConfigProperties('basemap', {
        'theme': 'faded',
        'lightPreset': 'night',
        'show3dObjects': true,
        'showPointOfInterestLabels': true,
        'showTransitLabels': true,
        'showPlaceLabels': true,
        'showRoadLabels': true,
        'showLandmarkIcons': true,
      });
    } catch (_) {
      // Keep the Standard style if a platform SDK ignores a config key.
    }
  }

  void _moveToCameraTargetIfNeeded() {
    final target = widget.cameraTarget;
    if (target == null || target.revision == _lastCameraRevision) return;
    if (_mapboxMap == null) return;

    _lastCameraRevision = target.revision;
    _mapboxMap!.easeTo(
      mb.CameraOptions(
        center: mb.Point(
          coordinates: mb.Position(target.longitude, target.latitude),
        ),
        zoom: target.zoom,
        bearing: _northUpBearing,
        pitch: _topDownPitch,
      ),
      mb.MapAnimationOptions(duration: 1000),
    );
  }

  void _scheduleMarkerRender({bool force = false}) {
    final markers = buildAnonymMapMarkers(widget.locations, widget.selfUserId);
    final fingerprint = anonymMapMarkerFingerprint(markers);
    if (!force && fingerprint == _markersFingerprint) return;

    _markersFingerprint = fingerprint;
    _queuedMarkers = markers;

    if (_annotationManager != null) {
      unawaited(_renderQueuedMarkers());
    }
  }

  Future<void> _renderQueuedMarkers() async {
    if (_renderLoopRunning) return;
    if (_annotationManager == null) return;
    _renderLoopRunning = true;
    var renderedFingerprint = '';

    try {
      while (mounted && _annotationManager != null) {
        if (renderedFingerprint == _markersFingerprint) {
          break;
        }

        renderedFingerprint = _markersFingerprint;
        final snapshot = List<AnonymMapMarkerData>.from(_queuedMarkers);
        final markerOptions = <mb.PointAnnotationOptions>[];
        for (final marker in snapshot) {
          _BuiltNativeMarker? built;
          try {
            built = await _buildNativeMarker(marker);
          } catch (error, stackTrace) {
            debugPrint('Failed to build native map marker: $error');
            debugPrintStack(stackTrace: stackTrace);
            built = await _buildFallbackNativeMarker(marker);
          }
          built ??= await _buildFallbackNativeMarker(marker);
          if (built == null) continue;
          markerOptions.add(
            mb.PointAnnotationOptions(
              geometry: mb.Point(
                coordinates: mb.Position(built.longitude, built.latitude),
              ),
              image: built.iconBytes,
              iconAnchor: mb.IconAnchor.BOTTOM,
              iconSize: 1.50,
              textField: built.label ?? '',
              textAnchor: mb.TextAnchor.TOP,
              textJustify: mb.TextJustify.CENTER,
              textOffset: [0, 1.05],
              textSize: 13,
              textColor: const Color(0xFFFFFFFF).toARGB32(),
              textHaloColor: const Color(0xCC292929).toARGB32(),
              textHaloWidth: 2.2,
              textHaloBlur: 0.7,
              symbolSortKey: built.memberCount.toDouble(),
            ),
          );
        }

        await _annotationManager!.deleteAll();
        if (markerOptions.isNotEmpty) {
          await _annotationManager!.createMulti(markerOptions);
        }
      }
    } finally {
      _renderLoopRunning = false;
    }
  }

  Future<_BuiltNativeMarker?> _buildNativeMarker(
    AnonymMapMarkerData marker,
  ) async {
    if (marker.members.isEmpty) return null;
    final selfUserId = widget.selfUserId;
    final includesSelf =
        selfUserId != null &&
        marker.members.any((member) => member.userId == selfUserId);

    if (marker.members.length == 1) {
      final member = marker.members.first;
      final isSelfMarker = includesSelf;
      final cacheKey = [
        'single',
        member.userId,
        member.avatarUrl ?? '',
        member.frameUrl ?? '',
        isSelfMarker ? 'self' : 'other',
        marker.label,
      ].join(':');
      final bytes = await _getOrCreateMarkerBytes(
        cacheKey: cacheKey,
        builder: () => _drawSingleAvatarMarker(
          member,
          isSelfMarker: isSelfMarker,
          labelText: marker.label,
        ),
      );

      return _BuiltNativeMarker(
        latitude: marker.latitude,
        longitude: marker.longitude,
        iconBytes: bytes,
        label: null,
        memberCount: marker.members.length,
      );
    }

    final displayMembers = marker.members.take(4).toList(growable: false);
    final avatarsKey = displayMembers
        .map(
          (member) =>
              '${member.userId}:${member.avatarUrl ?? ''}:${member.frameUrl ?? ''}',
        )
        .join('|');
    final cacheKey =
        'cluster:${marker.members.length}:$avatarsKey:${marker.label}';
    final bytes = await _getOrCreateMarkerBytes(
      cacheKey: cacheKey,
      builder: () =>
          _drawClusterAvatarMarker(displayMembers, labelText: marker.label),
    );

    return _BuiltNativeMarker(
      latitude: marker.latitude,
      longitude: marker.longitude,
      iconBytes: bytes,
      label: null,
      memberCount: marker.members.length,
    );
  }

  Future<_BuiltNativeMarker?> _buildFallbackNativeMarker(
    AnonymMapMarkerData marker,
  ) async {
    if (marker.members.isEmpty) return null;
    final selfUserId = widget.selfUserId;
    final isSelfMarker =
        marker.members.length == 1 &&
        selfUserId != null &&
        marker.members.first.userId == selfUserId;
    final member = marker.members.first;
    final cacheKey = [
      'fallback',
      member.userId,
      member.initials,
      member.frameUrl ?? '',
      isSelfMarker ? 'self' : 'other',
      marker.label,
    ].join(':');
    final bytes = await _getOrCreateMarkerBytes(
      cacheKey: cacheKey,
      builder: () => _drawFallbackDiscMarker(
        member,
        isSelfMarker: isSelfMarker,
        labelText: marker.label,
      ),
    );

    return _BuiltNativeMarker(
      latitude: marker.latitude,
      longitude: marker.longitude,
      iconBytes: bytes,
      label: null,
      memberCount: marker.members.length,
    );
  }

  Future<Uint8List> _getOrCreateMarkerBytes({
    required String cacheKey,
    required Future<Uint8List> Function() builder,
  }) async {
    final cached = _markerBytesCache[cacheKey];
    if (cached != null) return cached;
    final created = await builder();
    _markerBytesCache[cacheKey] = created;
    return created;
  }

  Future<Uint8List> _drawSingleAvatarMarker(
    AnonymMapMarkerMember member, {
    required bool isSelfMarker,
    required String labelText,
  }) async {
    final showLabel = labelText.trim().isNotEmpty;
    final labelPainter = showLabel ? _buildMarkerLabelPainter(labelText) : null;
    final labelVerticalPadding = showLabel ? 5.0 : 0.0;
    final labelHorizontalPadding = showLabel ? 14.0 : 0.0;
    final labelHeight = labelPainter == null
        ? 0.0
        : labelPainter.height + (labelVerticalPadding * 2);
    final labelWidth = labelPainter == null
        ? 0.0
        : labelPainter.width + (labelHorizontalPadding * 2);

    final avatarRadius = isSelfMarker ? 46.0 : 41.0;
    final avatarDiameter = avatarRadius * 2;
    final markerWidth = showLabel
        ? max(avatarDiameter + 24, labelWidth + 18)
        : avatarDiameter + 28;
    final markerHeight = showLabel
        ? labelHeight + avatarDiameter + 34
        : avatarDiameter + 28;

    final canvasSize = ui.Size(markerWidth, markerHeight);
    final avatarCenter = Offset(
      canvasSize.width / 2,
      avatarRadius + (showLabel ? 12 : 14),
    );
    final avatarImage = await _resolveAvatarImage(member.avatarUrl);
    final frameImage = await _resolveAvatarImage(member.frameUrl);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final shadowPaint = Paint()
      ..color = const Color(0x55292929)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(
      avatarCenter + const Offset(0, 4),
      avatarRadius,
      shadowPaint,
    );

    _drawAvatarCircle(
      canvas: canvas,
      center: avatarCenter,
      radius: avatarRadius,
      avatar: avatarImage,
      fallbackColor: member.fallbackColor,
      fallbackText: member.initials,
    );

    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..color = Colors.white;
    canvas.drawCircle(avatarCenter, avatarRadius, outlinePaint);
    _drawAvatarFrame(
      canvas: canvas,
      center: avatarCenter,
      radius: avatarRadius,
      frame: frameImage,
    );

    if (showLabel && labelPainter != null) {
      final labelRect = Rect.fromCenter(
        center: Offset(
          canvasSize.width / 2,
          avatarCenter.dy + avatarRadius + 8 + (labelHeight / 2),
        ),
        width: labelWidth,
        height: labelHeight,
      );
      _drawMarkerLabelPill(
        canvas: canvas,
        rect: labelRect,
        painter: labelPainter,
      );
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      canvasSize.width.toInt(),
      canvasSize.height.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    picture.dispose();
    image.dispose();
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _drawClusterAvatarMarker(
    List<AnonymMapMarkerMember> members, {
    required String labelText,
  }) async {
    final showLabel = labelText.trim().isNotEmpty;
    final labelPainter = showLabel ? _buildMarkerLabelPainter(labelText) : null;
    final labelVerticalPadding = showLabel ? 5.0 : 0.0;
    final labelHorizontalPadding = showLabel ? 14.0 : 0.0;
    final labelHeight = labelPainter == null
        ? 0.0
        : labelPainter.height + (labelVerticalPadding * 2);
    final labelWidth = labelPainter == null
        ? 0.0
        : labelPainter.width + (labelHorizontalPadding * 2);

    const avatarRadius = 36.0;
    const overlap = 28.0;
    const avatarsPadding = 9.0;
    final avatarsWidth =
        (avatarRadius * 2) +
        (members.length - 1) * overlap +
        (avatarsPadding * 2);
    final avatarsHeight = (avatarRadius * 2) + (avatarsPadding * 2);
    final width = showLabel ? max(avatarsWidth, labelWidth + 18) : avatarsWidth;
    final height = showLabel ? avatarsHeight + labelHeight + 18 : avatarsHeight;
    final canvasSize = ui.Size(width, height);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final avatarsContentWidth =
        (avatarRadius * 2) + (members.length - 1) * overlap;
    final startX =
        ((canvasSize.width - avatarsContentWidth) / 2) + avatarRadius;
    const avatarsTop = 0.0;
    final centerY = avatarsTop + avatarRadius + avatarsPadding;

    for (var i = 0; i < members.length; i++) {
      final member = members[i];
      final center = Offset(startX + i * overlap, centerY);
      final avatarImage = await _resolveAvatarImage(member.avatarUrl);
      final frameImage = await _resolveAvatarImage(member.frameUrl);

      final shadowPaint = Paint()
        ..color = const Color(0x55292929)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
      canvas.drawCircle(center + const Offset(0, 3), avatarRadius, shadowPaint);

      _drawAvatarCircle(
        canvas: canvas,
        center: center,
        radius: avatarRadius,
        avatar: avatarImage,
        fallbackColor: member.fallbackColor,
        fallbackText: member.initials,
      );

      final outlinePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..color = Colors.white;
      canvas.drawCircle(center, avatarRadius, outlinePaint);
      _drawAvatarFrame(
        canvas: canvas,
        center: center,
        radius: avatarRadius,
        frame: frameImage,
      );
    }

    if (showLabel && labelPainter != null) {
      final labelRect = Rect.fromCenter(
        center: Offset(
          canvasSize.width / 2,
          avatarsHeight + 8 + (labelHeight / 2),
        ),
        width: labelWidth,
        height: labelHeight,
      );
      _drawMarkerLabelPill(
        canvas: canvas,
        rect: labelRect,
        painter: labelPainter,
      );
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      canvasSize.width.toInt(),
      canvasSize.height.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    picture.dispose();
    image.dispose();
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _drawFallbackDiscMarker(
    AnonymMapMarkerMember member, {
    required bool isSelfMarker,
    required String labelText,
  }) async {
    final showLabel = labelText.trim().isNotEmpty;
    final labelPainter = showLabel ? _buildMarkerLabelPainter(labelText) : null;
    final labelVerticalPadding = showLabel ? 5.0 : 0.0;
    final labelHorizontalPadding = showLabel ? 14.0 : 0.0;
    final labelHeight = labelPainter == null
        ? 0.0
        : labelPainter.height + (labelVerticalPadding * 2);
    final labelWidth = labelPainter == null
        ? 0.0
        : labelPainter.width + (labelHorizontalPadding * 2);

    final radius = isSelfMarker ? 43.0 : 39.0;
    final diameter = radius * 2;
    final markerWidth = showLabel
        ? max(diameter + 24, labelWidth + 18)
        : diameter + 28;
    final markerHeight = showLabel
        ? labelHeight + diameter + 34
        : diameter + 28;
    final canvasSize = ui.Size(markerWidth, markerHeight);
    final center = Offset(canvasSize.width / 2, radius + (showLabel ? 12 : 14));
    final frameImage = await _resolveAvatarImage(member.frameUrl);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final shadowPaint = Paint()
      ..color = const Color(0x55292929)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    canvas.drawCircle(center + const Offset(0, 3), radius, shadowPaint);

    canvas.drawCircle(center, radius, Paint()..color = member.fallbackColor);
    _drawCenteredText(
      canvas: canvas,
      text: member.initials,
      center: center,
      fontSize: isSelfMarker ? 30 : 27,
      color: Colors.white,
    );

    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..color = Colors.white;
    canvas.drawCircle(center, radius, outlinePaint);
    _drawAvatarFrame(
      canvas: canvas,
      center: center,
      radius: radius,
      frame: frameImage,
    );

    if (showLabel && labelPainter != null) {
      final labelRect = Rect.fromCenter(
        center: Offset(
          canvasSize.width / 2,
          center.dy + radius + 8 + (labelHeight / 2),
        ),
        width: labelWidth,
        height: labelHeight,
      );
      _drawMarkerLabelPill(
        canvas: canvas,
        rect: labelRect,
        painter: labelPainter,
      );
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      canvasSize.width.toInt(),
      canvasSize.height.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    picture.dispose();
    image.dispose();
    return byteData!.buffer.asUint8List();
  }

  void _drawAvatarCircle({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required ui.Image? avatar,
    required Color fallbackColor,
    required String fallbackText,
  }) {
    final circleRect = Rect.fromCircle(center: center, radius: radius);
    final circlePath = Path()..addOval(circleRect);

    canvas.save();
    canvas.clipPath(circlePath);
    if (avatar != null) {
      _drawFittedImage(
        canvas: canvas,
        image: avatar,
        destination: circleRect,
        fit: BoxFit.cover,
      );
    } else {
      canvas.drawCircle(center, radius, Paint()..color = fallbackColor);
      _drawCenteredText(
        canvas: canvas,
        text: fallbackText,
        center: center,
        fontSize: radius * 0.8,
        color: Colors.white,
      );
    }
    canvas.restore();
  }

  void _drawAvatarFrame({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required ui.Image? frame,
  }) {
    if (frame == null) return;
    final frameRect = Rect.fromCircle(center: center, radius: radius + 1);
    _drawFittedImage(
      canvas: canvas,
      image: frame,
      destination: frameRect,
      fit: BoxFit.contain,
    );
  }

  void _drawFittedImage({
    required Canvas canvas,
    required ui.Image image,
    required Rect destination,
    required BoxFit fit,
  }) {
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    if (imageSize.width <= 0 || imageSize.height <= 0) return;
    final fitted = applyBoxFit(fit, imageSize, destination.size);
    final src = Alignment.center.inscribe(
      fitted.source,
      Offset.zero & imageSize,
    );
    final dst = Alignment.center.inscribe(fitted.destination, destination);
    canvas.drawImageRect(image, src, dst, Paint());
  }

  void _drawCenteredText({
    required Canvas canvas,
    required String text,
    required Offset center,
    required double fontSize,
    required Color color,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  TextPainter _buildMarkerLabelPainter(String text) {
    final normalized = text.trim().isEmpty ? 'Moi' : text.trim();
    return TextPainter(
      text: TextSpan(
        text: normalized,
        style: const TextStyle(
          color: AppColors.whiteColor,
          fontSize: 25.0,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: 156);
  }

  void _drawMarkerLabelPill({
    required Canvas canvas,
    required Rect rect,
    required TextPainter painter,
  }) {
    const radius = Radius.circular(8);
    final labelRRect = RRect.fromRectAndRadius(rect, radius);
    canvas.drawRRect(
      labelRRect,
      Paint()..color = AppColors.textPrimary.withValues(alpha: 0.80),
    );
    painter.paint(
      canvas,
      Offset(
        rect.left + ((rect.width - painter.width) / 2),
        rect.top + ((rect.height - painter.height) / 2),
      ),
    );
  }

  Future<ui.Image?> _resolveAvatarImage(String? avatarUrl) async {
    final normalized = avatarUrl?.trim();
    if (normalized == null || normalized.isEmpty) return null;

    if (_avatarImageCache.containsKey(normalized)) {
      return _avatarImageCache[normalized];
    }

    final inFlight = _avatarInFlight[normalized];
    if (inFlight != null) return inFlight;

    final future = _loadAvatarImage(normalized);
    _avatarInFlight[normalized] = future;
    final image = await future;
    _avatarInFlight.remove(normalized);
    _avatarImageCache[normalized] = image;
    return image;
  }

  Future<ui.Image?> _loadAvatarImage(String avatarUrl) async {
    final uri = Uri.tryParse(avatarUrl);
    if (uri == null) return null;

    try {
      final byteData = await NetworkAssetBundle(uri).load(uri.toString());
      final bytes = byteData.buffer.asUint8List();
      if (_looksLikeSvg(avatarUrl, bytes)) {
        return _decodeSvgImage(bytes);
      }
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 128,
        targetHeight: 128,
      );
      final frame = await codec.getNextFrame();
      codec.dispose();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  bool _looksLikeSvg(String avatarUrl, Uint8List bytes) {
    if (_isLikelySvgUrl(avatarUrl)) return true;

    final headerLength = min(bytes.length, 256);
    final header = utf8.decode(
      bytes.take(headerLength).toList(),
      allowMalformed: true,
    );
    return header.toLowerCase().contains('<svg');
  }

  bool _isLikelySvgUrl(String? value) {
    final lower = value?.toLowerCase().trim();
    if (lower == null || lower.isEmpty) return false;
    return lower.endsWith('.svg') || lower.contains('.svg?');
  }

  Future<ui.Image?> _decodeSvgImage(Uint8List bytes) async {
    final pictureInfo = await svg.vg.loadPicture(
      svg.SvgBytesLoader(bytes),
      null,
    );
    try {
      const targetPixels = 192;
      const targetSize = Size(192.0, 192.0);
      final picture = pictureInfo.picture;
      final sourceRect = _svgSourceRect(pictureInfo: pictureInfo);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Offset.zero & targetSize);

      final fitted = applyBoxFit(BoxFit.contain, sourceRect.size, targetSize);
      final destinationRect = Alignment.center.inscribe(
        fitted.destination,
        Offset.zero & targetSize,
      );
      final scaleX = destinationRect.width / sourceRect.width;
      final scaleY = destinationRect.height / sourceRect.height;

      canvas.save();
      canvas.translate(
        destinationRect.left - (sourceRect.left * scaleX),
        destinationRect.top - (sourceRect.top * scaleY),
      );
      canvas.scale(scaleX, scaleY);
      canvas.drawPicture(picture);
      canvas.restore();

      final rasterizedPicture = recorder.endRecording();
      try {
        return await rasterizedPicture.toImage(targetPixels, targetPixels);
      } finally {
        rasterizedPicture.dispose();
      }
    } catch (_) {
      try {
        return await pictureInfo.picture.toImage(192, 192);
      } catch (_) {
        return null;
      }
    } finally {
      pictureInfo.picture.dispose();
    }
  }

  Rect _svgSourceRect({required svg.PictureInfo pictureInfo}) {
    final width = pictureInfo.size.width;
    final height = pictureInfo.size.height;
    if (width.isFinite && height.isFinite && width > 0 && height > 0) {
      return Rect.fromLTWH(0, 0, width, height);
    }

    return const Rect.fromLTWH(0, 0, 192, 192);
  }
}

class _BuiltNativeMarker {
  const _BuiltNativeMarker({
    required this.latitude,
    required this.longitude,
    required this.iconBytes,
    required this.label,
    required this.memberCount,
  });

  final double latitude;
  final double longitude;
  final Uint8List iconBytes;
  final String? label;
  final int memberCount;
}
