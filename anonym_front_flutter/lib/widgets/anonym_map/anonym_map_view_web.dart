// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:async';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import '../../models/live_user_location_model.dart';
import '../../theme.dart';
import '../../utils/app_config.dart';
import '../../utils/app_logger.dart';
import 'anonym_map_data.dart';
import 'anonym_map_helpers.dart';

/// Web implementation of [AnonymMapView] using a JS bridge to Mapbox GL.
///
/// {@tool snippet}
/// AnonymMapView(
///   locations: app.liveLocations,
///   selfUserId: auth.user?.id,
///   cameraTarget: app.mapCameraTarget,
/// )
/// {@end-tool}
///
/// Error cases:
/// - Requires JS bridge methods (`anonymMapCreate`, `anonymMapUpdate`,
///   `anonymMapDispose`) to be available in the hosting page.
/// - Missing Mapbox JS/CSS or invalid token can leave the map blank.
class AnonymMapView extends StatefulWidget {
  const AnonymMapView({
    super.key,
    required this.locations,
    required this.selfUserId,
    this.cameraTarget,
  });

  final List<LiveUserLocationModel> locations;
  final int? selfUserId;
  final AnonymMapCameraTarget? cameraTarget;

  @override
  State<AnonymMapView> createState() => _AnonymMapViewState();
}

class _AnonymMapViewState extends State<AnonymMapView> {
  static int _nextViewId = 0;

  late final String _elementId = 'anonym-mapbox-gl-${_nextViewId++}';
  late final String _viewType = 'anonym-mapbox-gl-view-$_elementId';

  bool _created = false;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      return html.DivElement()
        ..id = _elementId
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.overflow = 'hidden'
        ..style.backgroundColor = '#393566';
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _createOrUpdateMap());
  }

  @override
  void didUpdateWidget(covariant AnonymMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _createOrUpdateMap());
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    if (_created) {
      _callBridge('anonymMapDispose', [_elementId]);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.hasMapboxAccessToken) {
      return const ColoredBox(
        color: AppColors.c393566,
        child: Center(
          child: Text(
            'Token Mapbox manquant.\nAjoutez --dart-define=MAPBOX_ACCESS_TOKEN=...',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.cFCFAFE,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        HtmlElementView(viewType: _viewType),
        if (!_isBridgeAvailable) const _MapBridgeWarning(),
      ],
    );
  }

  bool get _isBridgeAvailable => js.context.hasProperty('anonymMapCreate');

  void _createOrUpdateMap() {
    if (!mounted) return;
    if (!AppConfig.hasMapboxAccessToken) return;
    final payloadMap = _payload();
    final markerList = payloadMap['markers'] as List<Object?>? ?? const [];
    final first = markerList.isEmpty ? null : markerList.first;
    AppLogger.debug(
      '[ANONYM_MAP][web][send] markers=${markerList.length} '
      'first=${first is Map ? '${first['latitude']},${first['longitude']}' : '-'} '
      'camera=${payloadMap['camera'] ?? '-'}',
    );
    final payload = jsonEncode(payloadMap);
    if (!_created) {
      _created = _callBridge('anonymMapCreate', [_elementId, payload]);
      if (!_created) {
        _scheduleRetry();
      }
      return;
    }
    final updated = _callBridge('anonymMapUpdate', [_elementId, payload]);
    if (!updated) {
      _created = false;
      _scheduleRetry();
    }
  }

  Map<String, Object?> _payload() {
    return {
      'accessToken': AppConfig.mapboxAccessToken,
      'markers': buildAnonymMapMarkers(
        widget.locations,
        widget.selfUserId,
      ).map((marker) => marker.toJson()).toList(),
      'camera': widget.cameraTarget?.toJson(),
    };
  }

  bool _callBridge(String method, List<Object?> args) {
    if (!js.context.hasProperty(method)) return false;
    try {
      final result = js.context.callMethod(method, args);
      if (result is bool) return result;
      return true;
    } catch (error) {
      AppLogger.debug('Mapbox bridge error: $error');
      return false;
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _createOrUpdateMap();
    });
  }
}

class _MapBridgeWarning extends StatelessWidget {
  const _MapBridgeWarning();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: ColoredBox(
        color: AppColors.c393566,
        child: Center(
          child: Text(
            'Chargement de Mapbox...',
            style: TextStyle(
              color: AppColors.cFCFAFE,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
