import 'package:anonym_front_flutter/utils/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('mapboxAccessToken returns a non-empty token', () {
    expect(AppConfig.mapboxAccessToken.trim(), isNotEmpty);
  });

  group('AppConfig.apiBaseUrl', () {
    test('returns fallback url for android override', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(AppConfig.apiBaseUrl, 'http://192.168.1.114:5000');
    });

    test('returns fallback url for iOS override', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(AppConfig.apiBaseUrl, 'http://192.168.1.114:5000');
    });

    test('returns fallback url for windows override', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(AppConfig.apiBaseUrl, 'http://192.168.1.114:5000');
    });

    test('returns fallback url for default branch (linux)', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      expect(AppConfig.apiBaseUrl, 'http://192.168.1.114:5000');
    });
  });
}
