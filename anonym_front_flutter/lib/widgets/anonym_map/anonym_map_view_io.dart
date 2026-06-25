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
import '../../utils/app_logger.dart';
import '../../utils/media_url.dart';
import '../app_remote_image.dart';
import 'anonym_map_data.dart';
import 'anonym_map_helpers.dart';

part 'anonym_map_view_io_native.dart';
part 'anonym_map_view_io_windows.dart';
part 'anonym_map_view_io_leaflet.dart';

/// IO implementation of [AnonymMapView] for Android/iOS/desktop.
///
/// Chooses a concrete renderer by platform:
/// - Android/iOS: native Mapbox SDK.
/// - Windows: WebView bridge.
/// - Other IO platforms: Leaflet fallback.
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
/// - Missing/invalid Mapbox token can prevent tiles from loading.
/// - Platform-specific plugins must be installed and configured.
class AnonymMapView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (!AppConfig.hasMapboxAccessToken) {
      return const _MapUnavailableMessage(
        message: 'Token Mapbox manquant.',
        detail: 'Ajoutez --dart-define=MAPBOX_ACCESS_TOKEN=...',
      );
    }

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
