import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_svg/flutter_svg.dart' as svg;
import 'package:latlong2/latlong.dart' as ll;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:webview_windows/webview_windows.dart' as wv;

import '../../models/live_user_location_model.dart';
import '../../theme.dart';
import '../../utils/app_config.dart';
import '../../utils/media_url.dart';
import '../app_remote_image.dart';
import 'moji_map_data.dart';
import 'moji_map_helpers.dart';

class MojiMapView extends StatelessWidget {
  const MojiMapView({
    super.key,
    required this.locations,
    required this.selfUserId,
    this.cameraTarget,
  });

  final List<LiveUserLocationModel> locations;
  final int? selfUserId;
  final MojiMapCameraTarget? cameraTarget;

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid || Platform.isIOS) {
      return _NativeMapboxMap(
        locations: locations,
        selfUserId: selfUserId,
        cameraTarget: cameraTarget,
      );
    }

    if (Platform.isWindows) {
      return _WindowsMapboxGlMap(
        locations: locations,
        selfUserId: selfUserId,
        cameraTarget: cameraTarget,
      );
    }

    return _LeafletMapFallback(
      locations: locations,
      selfUserId: selfUserId,
      cameraTarget: cameraTarget,
    );
  }
}

class _NativeMapboxMap extends StatefulWidget {
  const _NativeMapboxMap({
    required this.locations,
    required this.selfUserId,
    required this.cameraTarget,
  });

  final List<LiveUserLocationModel> locations;
  final int? selfUserId;
  final MojiMapCameraTarget? cameraTarget;

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

  List<MojiMapMarkerData> _queuedMarkers = const [];
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
    await _applyMojiMapTheme(mapboxMap);
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

  Future<void> _applyMojiMapTheme(mb.MapboxMap mapboxMap) async {
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
    final markers = buildMojiMapMarkers(widget.locations, widget.selfUserId);
    final fingerprint = mojiMapMarkerFingerprint(markers);
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
        final snapshot = List<MojiMapMarkerData>.from(_queuedMarkers);
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
    MojiMapMarkerData marker,
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
    MojiMapMarkerData marker,
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
    MojiMapMarkerMember member, {
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
    List<MojiMapMarkerMember> members, {
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
    MojiMapMarkerMember member, {
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

class _WindowsMapboxGlMap extends StatefulWidget {
  const _WindowsMapboxGlMap({
    required this.locations,
    required this.selfUserId,
    required this.cameraTarget,
  });

  final List<LiveUserLocationModel> locations;
  final int? selfUserId;
  final MojiMapCameraTarget? cameraTarget;

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

    final markers = buildMojiMapMarkers(widget.locations, widget.selfUserId);
    final message = {
      'type': 'state',
      'markers': markers.map((marker) => marker.toJson()).toList(),
      'camera': widget.cameraTarget?.toJson(),
    };
    final first = markers.isEmpty ? null : markers.first;
    debugPrint(
      '[MOJI_MAP][windows][send] markers=${markers.length} '
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

class _LeafletMapFallback extends StatefulWidget {
  const _LeafletMapFallback({
    required this.locations,
    required this.selfUserId,
    required this.cameraTarget,
  });

  final List<LiveUserLocationModel> locations;
  final int? selfUserId;
  final MojiMapCameraTarget? cameraTarget;

  @override
  State<_LeafletMapFallback> createState() => _LeafletMapFallbackState();
}

class _LeafletMapFallbackState extends State<_LeafletMapFallback> {
  static const _mapboxTileUrl =
      'https://api.mapbox.com/styles/v1/mapbox/light-v11/tiles/256/'
      '{z}/{x}/{y}{r}?access_token={accessToken}';

  final fm.MapController _mapController = fm.MapController();
  int? _lastCameraRevision;

  @override
  void didUpdateWidget(covariant _LeafletMapFallback oldWidget) {
    super.didUpdateWidget(oldWidget);
    _moveToCameraTargetIfNeeded();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final markers = buildMojiMapMarkers(widget.locations, widget.selfUserId);
    return fm.FlutterMap(
      mapController: _mapController,
      options: fm.MapOptions(
        initialCenter: const ll.LatLng(48.8566, 2.3522),
        initialZoom: 12,
        minZoom: 2,
        maxZoom: 19,
        backgroundColor: AppColors.c393566,
        interactionOptions: const fm.InteractionOptions(
          flags: fm.InteractiveFlag.all,
        ),
        onMapReady: _moveToCameraTargetIfNeeded,
      ),
      children: [
        fm.TileLayer(
          urlTemplate: _mapboxTileUrl,
          additionalOptions: {
            'accessToken': Uri.encodeQueryComponent(
              AppConfig.mapboxAccessToken,
            ),
          },
          maxNativeZoom: 22,
          retinaMode: true,
          userAgentPackageName: 'anonym_front_flutter',
        ),
        fm.MarkerLayer(
          markers: [
            for (final marker in markers)
              fm.Marker(
                key: ValueKey(marker.key),
                point: ll.LatLng(marker.latitude, marker.longitude),
                width: 300,
                height: 180,
                alignment: Alignment.center,
                rotate: true,
                child: _LeafletMarker(marker: marker),
              ),
          ],
        ),
      ],
    );
  }

  void _moveToCameraTargetIfNeeded() {
    final target = widget.cameraTarget;
    if (target == null || target.revision == _lastCameraRevision) return;
    _lastCameraRevision = target.revision;
    _mapController.move(
      ll.LatLng(target.latitude, target.longitude),
      target.zoom,
    );
  }
}

class _LeafletMarker extends StatelessWidget {
  const _LeafletMarker({required this.marker});

  final MojiMapMarkerData marker;

  @override
  Widget build(BuildContext context) {
    final displayMembers = marker.members.take(4).toList(growable: false);
    final avatarSize = marker.members.length == 1 ? 92.0 : 76.0;
    final overlap = marker.members.length == 1 ? 0.0 : 29.0;
    final stackWidth = avatarSize + (displayMembers.length - 1) * overlap;

    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: max(stackWidth, avatarSize),
            height: avatarSize + 10,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < displayMembers.length; i++)
                  Positioned(
                    left: i * overlap,
                    top: 0,
                    child: _FlutterAvatarDisc(
                      member: displayMembers[i],
                      size: avatarSize,
                    ),
                  ),
                if (marker.members.length > displayMembers.length)
                  Positioned(
                    right: -10,
                    top: -8,
                    child: _ClusterCountBadge(
                      count: marker.members.length - displayMembers.length,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.c292929.withValues(alpha: 0.66),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.whiteColor.withValues(alpha: 0.28),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              child: Text(
                marker.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.whiteColor,
                  fontSize: 25.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlutterAvatarDisc extends StatelessWidget {
  const _FlutterAvatarDisc({required this.member, required this.size});

  final MojiMapMarkerMember member;
  final double size;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = MediaUrl.nullable(member.avatarUrl);
    final frameUrl = MediaUrl.nullable(member.frameUrl);

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.c292929.withValues(alpha: 0.34),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.cFCFAFE, width: 2.2),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ClipOval(
                child: avatarUrl == null
                    ? _AvatarFallback(member: member, size: size)
                    : AppRemoteImage(
                        url: avatarUrl,
                        fit: BoxFit.cover,
                        fallbackIcon: Icons.alternate_email,
                      ),
              ),
            ),
            if (frameUrl != null)
              Positioned(
                left: -1,
                top: -1,
                right: -1,
                bottom: -1,
                child: IgnorePointer(
                  child: AppRemoteImage(
                    url: frameUrl,
                    fit: BoxFit.contain,
                    fallbackIcon: Icons.image_not_supported,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.member, required this.size});

  final MojiMapMarkerMember member;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: member.fallbackColor,
      child: Center(
        child: Text(
          member.initials,
          style: TextStyle(
            color: AppColors.cFCFAFE,
            fontSize: max(18, size * 0.34),
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _ClusterCountBadge extends StatelessWidget {
  const _ClusterCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.c393566,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.cFCFAFE, width: 2),
      ),
      child: SizedBox(
        width: 30,
        height: 30,
        child: Center(
          child: Text(
            '+$count',
            style: const TextStyle(
              color: AppColors.cFCFAFE,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _MapLoadingMessage extends StatelessWidget {
  const _MapLoadingMessage();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.c393566,
      child: Center(child: CircularProgressIndicator(color: AppColors.cFCFAFE)),
    );
  }
}

class _MapUnavailableMessage extends StatelessWidget {
  const _MapUnavailableMessage({required this.message, this.detail});

  final String message;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.c393566,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            detail == null ? message : '$message\n$detail',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.cFCFAFE,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ),
    );
  }
}

String _windowsMapHtml(String accessToken) {
  final tokenJson = jsonEncode(accessToken);
  return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="https://api.mapbox.com/mapbox-gl-js/v3.10.0/mapbox-gl.css">
  <style>
    html, body, #map {
      background: #393566;
      height: 100%;
      margin: 0;
      overflow: hidden;
      width: 100%;
    }

    .moji-map-loading {
      align-items: center;
      color: #FCFAFE;
      display: flex;
      font: 600 15px system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      height: 100%;
      justify-content: center;
      text-align: center;
      width: 100%;
    }

    .moji-map-marker {
      align-items: center;
      display: flex;
      flex-direction: column;
      pointer-events: none;
    }

    .moji-map-avatars {
      position: relative;
    }

    .moji-map-avatar {
      align-items: center;
      border: 2.2px solid #FCFAFE;
      border-radius: 999px;
      box-shadow: 0 5px 12px rgba(41, 41, 41, 0.36);
      color: #FCFAFE;
      display: flex;
      justify-content: center;
      overflow: hidden;
      position: absolute;
      top: 0;
    }

    .moji-map-avatar img {
      height: 100%;
      object-fit: cover;
      width: 100%;
    }

    .moji-map-initials {
      color: #FCFAFE;
      font: 800 22px system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      letter-spacing: 0;
    }

    .moji-map-badge {
      align-items: center;
      background: #393566;
      border: 2px solid #FCFAFE;
      border-radius: 999px;
      color: #FCFAFE;
      display: flex;
      font: 800 10px system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      height: 24px;
      justify-content: center;
      position: absolute;
      right: -8px;
      top: -6px;
      width: 24px;
    }

    .moji-map-label {
      background: rgba(41, 41, 41, 0.66);
      border: 1px solid rgba(252, 250, 254, 0.28);
      border-radius: 12px;
      color: #FCFAFE;
      font: 700 12.5px system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      letter-spacing: 0;
      margin-top: 2px;
      max-width: 170px;
      overflow: hidden;
      padding: 4px 12px;
      text-align: center;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
  </style>
</head>
<body>
  <div id="map"><div class="moji-map-loading">Chargement de Mapbox...</div></div>
  <script src="https://api.mapbox.com/mapbox-gl-js/v3.10.0/mapbox-gl.js"></script>
  <script>
    const accessToken = $tokenJson;
    const initialCenter = [2.3522, 48.8566];
    const logPrefix = "[MOJI_MAP][windows]";
    let map;
    let ready = false;
    let lastCameraRevision = null;
    const markers = new Map();
    let fallbackMarker = null;
    let fallbackLabel = null;

    function log(message, data) {
      if (data === undefined) {
        console.log(logPrefix, message);
        return;
      }
      console.log(logPrefix, message, data);
    }

    function mapConfig() {
      return {
        basemap: {
          theme: "faded",
          lightPreset: "night",
          show3dObjects: true,
          showPointOfInterestLabels: true,
          showTransitLabels: true,
          showPlaceLabels: true,
          showRoadLabels: true,
        },
      };
    }

    function applyStandardConfig() {
      const basemap = mapConfig().basemap;
      for (const key of Object.keys(basemap)) {
        try {
          map.setConfigProperty("basemap", key, basemap[key]);
        } catch (_) {}
      }
    }

    function postReady() {
      if (window.chrome && window.chrome.webview) {
        window.chrome.webview.postMessage({ type: "ready" });
      }
    }

    function parseMessage(raw) {
      if (typeof raw === "string") {
        try {
          return JSON.parse(raw);
        } catch (_) {
          return {};
        }
      }
      return raw || {};
    }

    function start() {
      if (!window.mapboxgl) return;
      mapboxgl.accessToken = accessToken;
      map = new mapboxgl.Map({
        container: "map",
        style: "mapbox://styles/mapbox/standard",
        center: initialCenter,
        zoom: 12,
        pitch: 0,
        bearing: 0,
        maxPitch: 0,
        pitchWithRotate: false,
        antialias: true,
        config: mapConfig(),
      });
      map.addControl(new mapboxgl.NavigationControl({ visualizePitch: false }), "top-right");
      map.on("style.load", applyStandardConfig);
      map.on("load", () => {
        ready = true;
        postReady();
      });
    }

    function handleMessage(raw) {
      const message = parseMessage(raw);
      if (!ready || message.type !== "state") return;
      log("state", {
        markerCount: Array.isArray(message.markers) ? message.markers.length : 0,
        camera: message.camera || null,
      });
      updateMarkers(message.markers || [], message.camera);
      focusCamera(message.camera);
    }

    function updateMarkers(markerData, camera) {
      const nextKeys = new Set(markerData.map((marker) => marker.key));
      for (const [key, entry] of markers.entries()) {
        const marker = entry && entry.pin ? entry.pin : entry;
        const label = entry && entry.label ? entry.label : null;
        if (!nextKeys.has(key)) {
          marker.remove();
          if (label) label.remove();
          markers.delete(key);
        }
      }
      for (const item of markerData) {
        const existing = markers.get(item.key);
        const lngLat = [item.longitude, item.latitude];
        if (existing) {
          existing.pin.setLngLat(lngLat);
          syncMoiLabel(existing, item, lngLat);
          continue;
        }
        const marker = new mapboxgl.Marker({
          anchor: "bottom",
        }).setLngLat(lngLat).addTo(map);
        const entry = { pin: marker, label: null };
        syncMoiLabel(entry, item, lngLat);
        markers.set(item.key, entry);
      }
      if (markerData.length > 0) {
        const first = markerData[0];
        log("markers:update", {
          count: markerData.length,
          first: {
            lat: first.latitude,
            lon: first.longitude,
            key: first.key,
          },
        });
      }

      if (markerData.length > 0) {
        clearFallbackMarker();
        return;
      }

      if (camera) {
        upsertFallbackMarker(camera);
      } else {
        clearFallbackMarker();
      }
    }

    function focusCamera(camera) {
      if (!camera || camera.revision === lastCameraRevision) return;
      lastCameraRevision = camera.revision;
      log("camera:focus", camera);
      map.easeTo({
        center: [camera.longitude, camera.latitude],
        zoom: camera.zoom || 13.5,
        pitch: 0,
        bearing: 0,
        duration: 1000,
        essential: true,
      });
    }

    function upsertFallbackMarker(camera) {
      const latitude = Number(camera.latitude);
      const longitude = Number(camera.longitude);
      if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) return;

      if (!fallbackMarker) {
        fallbackMarker = new mapboxgl.Marker({
          anchor: "bottom",
        }).setLngLat([longitude, latitude]).addTo(map);
        fallbackLabel = new mapboxgl.Marker({
          element: buildMoiLabelElement(),
          anchor: "top",
          offset: [0, 10],
        }).setLngLat([longitude, latitude]).addTo(map);
        log("fallback:create", { lat: latitude, lon: longitude });
        return;
      }

      fallbackMarker.setLngLat([longitude, latitude]);
      if (fallbackLabel) {
        fallbackLabel.setLngLat([longitude, latitude]);
      }
      log("fallback:move", { lat: latitude, lon: longitude });
    }

    function syncMoiLabel(entry, item, lngLat) {
      const shouldShow = isMoiMarker(item);
      if (!shouldShow) {
        if (entry.label) {
          entry.label.remove();
          entry.label = null;
        }
        return;
      }

      if (!entry.label) {
        entry.label = new mapboxgl.Marker({
          element: buildMoiLabelElement(),
          anchor: "top",
          offset: [0, 10],
        }).setLngLat(lngLat).addTo(map);
        return;
      }

      entry.label.setLngLat(lngLat);
    }

    function isMoiMarker(item) {
      const label = typeof item.label === "string" ? item.label.toLowerCase() : "";
      return label.includes("moi");
    }

    function buildMoiLabelElement() {
      const label = document.createElement("div");
      label.textContent = "moi";
      label.style.pointerEvents = "none";
      label.style.background = "rgba(41, 41, 41, 0.66)";
      label.style.border = "1px solid rgba(252, 250, 254, 0.28)";
      label.style.borderRadius = "12px";
      label.style.color = "#FCFAFE";
      label.style.font = "700 12px system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif";
      label.style.padding = "4px 12px";
      label.style.whiteSpace = "nowrap";
      return label;
    }

    function clearFallbackMarker() {
      if (!fallbackMarker) return;
      fallbackMarker.remove();
      fallbackMarker = null;
      if (fallbackLabel) {
        fallbackLabel.remove();
        fallbackLabel = null;
      }
    }

    if (window.chrome && window.chrome.webview) {
      window.chrome.webview.addEventListener("message", (event) => handleMessage(event.data));
    }
    start();
  </script>
</body>
</html>
''';
}
