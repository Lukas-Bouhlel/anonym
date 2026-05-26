part of 'anonym_map_view_io.dart';

class _LeafletMapFallback extends StatefulWidget {
  const _LeafletMapFallback({
    required this.locations,
    required this.selfUserId,
    required this.cameraTarget,
  });

  final List<LiveUserLocationModel> locations;
  final int? selfUserId;
  final AnonymMapCameraTarget? cameraTarget;

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
    final markers = buildAnonymMapMarkers(widget.locations, widget.selfUserId);
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

  final AnonymMapMarkerData marker;

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

  final AnonymMapMarkerMember member;
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

  final AnonymMapMarkerMember member;
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

    .anonym-map-loading {
      align-items: center;
      color: #FCFAFE;
      display: flex;
      font: 600 15px system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      height: 100%;
      justify-content: center;
      text-align: center;
      width: 100%;
    }

    .anonym-map-marker {
      align-items: center;
      display: flex;
      flex-direction: column;
      pointer-events: none;
    }

    .anonym-map-avatars {
      position: relative;
    }

    .anonym-map-avatar {
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

    .anonym-map-avatar img {
      height: 100%;
      object-fit: cover;
      width: 100%;
    }

    .anonym-map-initials {
      color: #FCFAFE;
      font: 800 22px system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      letter-spacing: 0;
    }

    .anonym-map-badge {
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

    .anonym-map-label {
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
  <div id="map"><div class="anonym-map-loading">Chargement de Mapbox...</div></div>
  <script src="https://api.mapbox.com/mapbox-gl-js/v3.10.0/mapbox-gl.js"></script>
  <script>
    const accessToken = $tokenJson;
    const initialCenter = [2.3522, 48.8566];
    const logPrefix = "[anonym_MAP][windows]";
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
