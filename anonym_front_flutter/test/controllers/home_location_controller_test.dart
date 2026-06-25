import 'dart:async';
import 'dart:math' as math;

import 'package:anonym_front_flutter/controllers/home_location_controller.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:flutter_test/flutter_test.dart';

class _FakeHomeGeoService extends HomeGeoService {
  _FakeHomeGeoService({this.lastKnown, this.current});

  static const bool _serviceEnabled = true;
  static const geo.LocationPermission _permission =
      geo.LocationPermission.always;
  final geo.Position? lastKnown;
  final geo.Position? current;
  final StreamController<geo.Position> _streamController =
      StreamController<geo.Position>.broadcast();

  @override
  Future<bool> isLocationServiceEnabled() async => _serviceEnabled;

  @override
  Future<geo.LocationPermission> checkPermission() async => _permission;

  @override
  Future<geo.LocationPermission> requestPermission() async => _permission;

  @override
  Future<geo.Position?> getLastKnownPosition() async => lastKnown;

  @override
  Future<geo.Position> getCurrentPosition({
    required geo.LocationSettings locationSettings,
  }) async {
    return current ?? _position(latitude: 0, longitude: 0, accuracy: 5);
  }

  @override
  Stream<geo.Position> getPositionStream({
    required geo.LocationSettings locationSettings,
  }) {
    return _streamController.stream;
  }

  @override
  double distanceBetween(double lat1, double lon1, double lat2, double lon2) {
    final dx = lat2 - lat1;
    final dy = lon2 - lon1;
    return math.sqrt(dx * dx + dy * dy) * 111000;
  }

  Future<void> dispose() async {
    await _streamController.close();
  }
}

geo.Position _position({
  required double latitude,
  required double longitude,
  required double accuracy,
}) {
  return geo.Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime.utc(2026, 1, 1),
    accuracy: accuracy,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeLocationController', () {
    test('accepts first fix, publishes and centers camera', () {
      final published = <Map<String, double>>[];
      final fakeGeo = _FakeHomeGeoService();
      final controller = HomeLocationController(
        publishMyLiveLocation:
            ({
              required double latitude,
              required double longitude,
              double? accuracy,
            }) {
              published.add({
                'latitude': latitude,
                'longitude': longitude,
                'accuracy': accuracy ?? 0,
              });
            },
        stopMyLiveLocationSharing: () {},
        activeFrameUrlForUser: (_) => 'frame.png',
        geoService: fakeGeo,
      );
      addTearDown(() async {
        await fakeGeo.dispose();
        controller.dispose();
      });

      controller.handleIncomingPosition(
        _position(latitude: 48.8566, longitude: 2.3522, accuracy: 8),
      );

      expect(published.length, 1);
      expect(published.first['latitude'], 48.8566);
      expect(published.first['longitude'], 2.3522);
      expect(controller.cameraTarget, isNotNull);
      expect(controller.cameraTarget!.latitude, 48.8566);
      expect(controller.cameraTarget!.longitude, 2.3522);
      expect(controller.cameraTarget!.revision, 1);
    });

    test('rejects jitter move under threshold and avoids extra publish', () {
      final published = <Map<String, double>>[];
      final fakeGeo = _FakeHomeGeoService();
      final controller = HomeLocationController(
        publishMyLiveLocation:
            ({
              required double latitude,
              required double longitude,
              double? accuracy,
            }) {
              published.add({
                'latitude': latitude,
                'longitude': longitude,
                'accuracy': accuracy ?? 0,
              });
            },
        stopMyLiveLocationSharing: () {},
        activeFrameUrlForUser: (_) => null,
        geoService: fakeGeo,
      );
      addTearDown(() async {
        await fakeGeo.dispose();
        controller.dispose();
      });

      controller.handleIncomingPosition(
        _position(latitude: 48.8566, longitude: 2.3522, accuracy: 5),
      );
      controller.handleIncomingPosition(
        _position(latitude: 48.8566005, longitude: 2.3522005, accuracy: 5),
      );

      expect(published.length, 1);
    });

    test('buildHydratedLocations includes local fallback marker', () {
      final fakeGeo = _FakeHomeGeoService();
      final controller = HomeLocationController(
        publishMyLiveLocation:
            ({
              required double latitude,
              required double longitude,
              double? accuracy,
            }) {},
        stopMyLiveLocationSharing: () {},
        activeFrameUrlForUser: (_) => 'frame.png',
        geoService: fakeGeo,
      );
      addTearDown(() async {
        await fakeGeo.dispose();
        controller.dispose();
      });

      controller.handleIncomingPosition(
        _position(latitude: 40.7128, longitude: -74.0060, accuracy: 6),
      );

      final hydrated = controller.buildHydratedLocations(
        liveLocations: const [],
        selfUserId: 42,
        selfUsername: 'Neo',
        selfAvatar: 'avatar.png',
      );

      expect(hydrated.length, 1);
      expect(hydrated.first.userId, 42);
      expect(hydrated.first.username, 'Neo');
      expect(hydrated.first.avatar, 'avatar.png');
      expect(hydrated.first.frameUrl, 'frame.png');
      expect(hydrated.first.latitude, 40.7128);
      expect(hydrated.first.longitude, -74.0060);
    });

    test(
      'startLocationTracking publishes last known and current positions',
      () async {
        final published = <Map<String, double>>[];
        final fakeGeo = _FakeHomeGeoService(
          lastKnown: _position(latitude: 10, longitude: 20, accuracy: 7),
          current: _position(latitude: 11, longitude: 21, accuracy: 7),
        );
        final controller = HomeLocationController(
          publishMyLiveLocation:
              ({
                required double latitude,
                required double longitude,
                double? accuracy,
              }) {
                published.add({
                  'latitude': latitude,
                  'longitude': longitude,
                  'accuracy': accuracy ?? 0,
                });
              },
          stopMyLiveLocationSharing: () {},
          activeFrameUrlForUser: (_) => null,
          geoService: fakeGeo,
          forcePollingLocationUpdates: false,
        );
        addTearDown(() async {
          await fakeGeo.dispose();
          controller.dispose();
        });

        await controller.startLocationTracking();

        expect(published.isNotEmpty, isTrue);
        expect(published.first['latitude'], 10);
      },
    );
  });
}
