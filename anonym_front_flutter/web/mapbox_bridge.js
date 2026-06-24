(function () {
  const maps = new Map();
  const initialCenter = [2.3522, 48.8566];
  const logPrefix = "[ANONYM_MAP][web]";
  const debugLogsEnabled =
    typeof window !== "undefined" && window.__ANONYM_MAP_DEBUG__ === true;

  function log(message, data) {
    if (!debugLogsEnabled) return;
    if (data === undefined) {
      console.log(logPrefix, message);
      return;
    }
    console.log(logPrefix, message, data);
  }

  function parsePayload(payload) {
    if (!payload) return {};
    if (typeof payload === "string") {
      try {
        return JSON.parse(payload);
      } catch (_) {
        return {};
      }
    }
    return payload;
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

  function applyStandardConfig(map) {
    const basemap = mapConfig().basemap;
    for (const key of Object.keys(basemap)) {
      try {
        map.setConfigProperty("basemap", key, basemap[key]);
      } catch (_) {
        // Older Mapbox GL builds may ignore newer Standard config keys.
      }
    }
  }

  function lockStandardNightMode(map) {
    applyStandardConfig(map);
    window.setTimeout(() => applyStandardConfig(map), 250);
    window.setTimeout(() => applyStandardConfig(map), 1000);
  }

  function createMap(elementId, payloadJson) {
    const payload = parsePayload(payloadJson);
    const container = document.getElementById(elementId);
    if (!container) return false;

    if (!window.mapboxgl) {
      container.innerHTML =
        '<div class="anonym-map-loading">Mapbox GL ne s\'est pas charge.</div>';
      return false;
    }

    if (maps.has(elementId)) {
      updateMap(elementId, payload);
      return true;
    }

    mapboxgl.accessToken = payload.accessToken || "";
    container.innerHTML = "";

    const map = new mapboxgl.Map({
      container,
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

    map.addControl(
      new mapboxgl.NavigationControl({ visualizePitch: false }),
      "top-right",
    );

    const state = {
      map,
      markers: new Map(),
      fallbackMarker: null,
      fallbackLabel: null,
      pendingPayload: payload,
      ready: false,
      lastCameraRevision: null,
    };
    maps.set(elementId, state);

    map.on("style.load", () => lockStandardNightMode(map));
    map.on("load", () => {
      state.ready = true;
      lockStandardNightMode(map);
      updateMap(elementId, state.pendingPayload || {});
    });
    return true;
  }

  function updateMap(elementId, payloadJson) {
    const state = maps.get(elementId);
    if (!state) return false;

    const payload = parsePayload(payloadJson);
    state.pendingPayload = payload;
    if (!state.ready) return true;
    log("state", {
      markerCount: Array.isArray(payload.markers) ? payload.markers.length : 0,
      camera: payload.camera || null,
    });

    updateMarkers(state, payload.markers || [], payload.camera);
    focusCamera(state, payload.camera);
    return true;
  }

  function updateMarkers(state, markerData, camera) {
    const nextKeys = new Set(markerData.map((marker) => marker.key));

    for (const [key, entry] of state.markers.entries()) {
      const marker = entry && entry.pin ? entry.pin : entry;
      const label = entry && entry.label ? entry.label : null;
      if (!nextKeys.has(key)) {
        marker.remove();
        if (label) label.remove();
        state.markers.delete(key);
      }
    }

    for (const item of markerData) {
      const existing = state.markers.get(item.key);
      const lngLat = [item.longitude, item.latitude];
      if (existing) {
        existing.pin.setLngLat(lngLat);
        _syncMoiLabel(state, existing, item, lngLat);
        continue;
      }

      const marker = new mapboxgl.Marker({
        anchor: "bottom",
      })
        .setLngLat(lngLat)
        .addTo(state.map);
      const entry = { pin: marker, label: null };
      _syncMoiLabel(state, entry, item, lngLat);
      state.markers.set(item.key, entry);
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
      clearFallbackMarker(state);
      return;
    }

    if (camera) {
      upsertFallbackMarker(state, camera);
    } else {
      clearFallbackMarker(state);
    }
  }

  function focusCamera(state, camera) {
    if (!camera || camera.revision === state.lastCameraRevision) return;
    state.lastCameraRevision = camera.revision;
    log("camera:focus", camera);
    state.map.easeTo({
      center: [camera.longitude, camera.latitude],
      zoom: camera.zoom || 13.5,
      pitch: 0,
      bearing: 0,
      duration: 1000,
      essential: true,
    });
  }

  function upsertFallbackMarker(state, camera) {
    const latitude = Number(camera.latitude);
    const longitude = Number(camera.longitude);
    if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) return;

    if (!state.fallbackMarker) {
      state.fallbackMarker = new mapboxgl.Marker({
        anchor: "bottom",
      })
        .setLngLat([longitude, latitude])
        .addTo(state.map);
      state.fallbackLabel = new mapboxgl.Marker({
        element: buildMoiLabelElement(),
        anchor: "top",
        offset: [0, 10],
      })
        .setLngLat([longitude, latitude])
        .addTo(state.map);
      log("fallback:create", { lat: latitude, lon: longitude });
      return;
    }

    state.fallbackMarker.setLngLat([longitude, latitude]);
    if (state.fallbackLabel) {
      state.fallbackLabel.setLngLat([longitude, latitude]);
    }
    log("fallback:move", { lat: latitude, lon: longitude });
  }

  function _syncMoiLabel(state, entry, item, lngLat) {
    const shouldShow = _isMoiMarker(item);
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
      })
        .setLngLat(lngLat)
        .addTo(state.map);
      return;
    }

    entry.label.setLngLat(lngLat);
  }

  function _isMoiMarker(item) {
    const label = typeof item.label === "string" ? item.label.toLowerCase() : "";
    return label.includes("moi");
  }

  function buildMoiLabelElement() {
    const label = document.createElement("div");
    label.textContent = "moi";
    label.style.pointerEvents = "none";
    label.style.background = "rgba(41, 41, 41, 0.66)";
    label.style.border = "1px solid rgba(252, 250, 254, 0.28)";
    label.style.borderRadius = "999px";
    label.style.color = "#FCFAFE";
    label.style.font = "700 12px system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif";
    label.style.padding = "4px 9px";
    label.style.whiteSpace = "nowrap";
    return label;
  }

  function clearFallbackMarker(state) {
    if (!state.fallbackMarker) return;
    state.fallbackMarker.remove();
    state.fallbackMarker = null;
    if (state.fallbackLabel) {
      state.fallbackLabel.remove();
      state.fallbackLabel = null;
    }
  }

  function disposeMap(elementId) {
    const state = maps.get(elementId);
    if (!state) return false;
    for (const entry of state.markers.values()) {
      if (entry && entry.label) entry.label.remove();
    }
    clearFallbackMarker(state);
    state.map.remove();
    maps.delete(elementId);
    return true;
  }

  window.anonymMapCreate = createMap;
  window.anonymMapUpdate = updateMap;
  window.anonymMapDispose = disposeMap;
})();
