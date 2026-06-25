import 'package:anonym_front_flutter/utils/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'mapboxAccessToken defaults to empty when no dart-define is provided',
    () {
      expect(AppConfig.mapboxAccessToken.trim(), isEmpty);
      expect(AppConfig.hasMapboxAccessToken, isFalse);
    },
  );

  group('AppConfig.apiBaseUrl', () {
    test('returns dev fallback url for android override', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(AppConfig.apiBaseUrl, 'http://10.70.0.118:5000');
    });

    test('returns fallback url for iOS override', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(AppConfig.apiBaseUrl, 'http://127.0.0.1:5000');
    });

    test('returns fallback url for windows override', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(AppConfig.apiBaseUrl, 'http://localhost:5000');
    });

    test('returns fallback url for default branch (linux)', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      expect(AppConfig.apiBaseUrl, 'http://localhost:5000');
    });
  });

  test('defaults to dev environment', () {
    expect(AppConfig.environment, AppEnvironment.dev);
  });
}
