import 'package:flutter/foundation.dart';

/// Configuration applicative centralisee (URL API, tokens, etc.).
abstract final class AppConfig {
  // Environnements supportes: dev | staging | prod.
  static const _appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'dev');

  // Base URLs par environnement.
  // Dev defaults intentionally avoid machine-specific LAN IPs.
  static const _devDefaultApiBaseUrl = 'http://localhost:5000';
  static const _devAndroidEmulatorApiBaseUrl = 'http://10.70.0.118:5000';
  static const _devIosSimulatorApiBaseUrl = 'http://127.0.0.1:5000';
  static const _stagingApiBaseUrl = 'https://staging-api.anonym-app.com';
  static const _prodApiBaseUrl = 'https://api.anonym-app.com';

  // Global override:
  // flutter run --dart-define=API_BASE_URL=http://localhost:5000
  static const _baseUrlFromEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  // Optional per-platform overrides:
  // flutter run --dart-define=API_BASE_URL_ANDROID=http://192.168.1.117:5000
  // flutter run --dart-define=API_BASE_URL_IOS=http://127.0.0.1:5000
  // flutter run --dart-define=API_BASE_URL_WINDOWS=http://localhost:5000
  static const _androidBaseUrlFromEnv = String.fromEnvironment(
    'API_BASE_URL_ANDROID',
    defaultValue: '',
  );
  static const _iosBaseUrlFromEnv = String.fromEnvironment(
    'API_BASE_URL_IOS',
    defaultValue: '',
  );
  static const _windowsBaseUrlFromEnv = String.fromEnvironment(
    'API_BASE_URL_WINDOWS',
    defaultValue: '',
  );
  static const _webBaseUrlFromEnv = String.fromEnvironment(
    'API_BASE_URL_WEB',
    defaultValue: '',
  );

  // Optional Mapbox override:
  // flutter run --dart-define=MAPBOX_ACCESS_TOKEN=pk...
  static const _mapboxTokenFromEnv = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
    defaultValue: '',
  );
  static const _tlsPinningEnabledFromEnv = String.fromEnvironment(
    'TLS_PINNING_ENABLED',
    defaultValue: '',
  );
  static const _tlsPinnedCertSha256FromEnv = String.fromEnvironment(
    'TLS_PINNED_CERT_SHA256',
    defaultValue: '',
  );
  static const _exposeBackendErrorsFromEnv = String.fromEnvironment(
    'EXPOSE_BACKEND_ERRORS',
    defaultValue: '',
  );

  static AppEnvironment get environment {
    switch (_appEnv.trim().toLowerCase()) {
      case 'prod':
      case 'production':
        return AppEnvironment.prod;
      case 'staging':
        return AppEnvironment.staging;
      default:
        return AppEnvironment.dev;
    }
  }

  /// Token Mapbox utilise par les widgets cartographiques.
  static String get mapboxAccessToken {
    return _mapboxTokenFromEnv.trim();
  }

  static bool get hasMapboxAccessToken => mapboxAccessToken.isNotEmpty;

  /// Active le pinning TLS natif (Android/iOS/desktop via Dio IO adapter).
  ///
  /// - `TLS_PINNING_ENABLED=true|false` force le comportement.
  /// - Sans variable: actif uniquement en staging/prod.
  static bool get isTlsPinningEnabled {
    final normalized = _tlsPinningEnabledFromEnv.trim().toLowerCase();
    if (normalized == '1' || normalized == 'true') return true;
    if (normalized == '0' || normalized == 'false') return false;
    return environment != AppEnvironment.dev;
  }

  /// Empreintes SHA-256 des certificats serveurs autorises (hex lowercase).
  ///
  /// Exemple:
  /// `--dart-define=TLS_PINNED_CERT_SHA256=abc...,def...`
  static List<String> get tlsPinnedCertSha256 {
    final raw = _tlsPinnedCertSha256FromEnv.trim();
    if (raw.isEmpty) return const <String>[];
    return raw
        .split(',')
        .map((value) => _normalizePin(value))
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  /// Contrôle l'exposition des messages backend bruts à l'UI.
  ///
  /// Par défaut:
  /// - `true` en debug dev (DX),
  /// - `false` ailleurs.
  static bool get exposeBackendErrors {
    final normalized = _exposeBackendErrorsFromEnv.trim().toLowerCase();
    if (normalized == '1' || normalized == 'true') return true;
    if (normalized == '0' || normalized == 'false') return false;
    return kDebugMode && environment == AppEnvironment.dev;
  }

  /// URL de base de l'API selon plateforme et variables d'environnement.
  static String get apiBaseUrl {
    final env = environment;
    final platformOverride = _platformOverride();
    final globalOverride = _baseUrlFromEnv.trim();
    final candidate = platformOverride.isNotEmpty
        ? platformOverride
        : (globalOverride.isNotEmpty
              ? globalOverride
              : _baseUrlForEnvironment(env));

    if (env != AppEnvironment.dev && !_isHttps(candidate)) {
      throw StateError(
        'Insecure API_BASE_URL for $env: "$candidate". HTTPS is required.',
      );
    }

    return candidate;
  }

  static String _baseUrlForEnvironment(AppEnvironment env) {
    switch (env) {
      case AppEnvironment.dev:
        return _devFallbackBaseUrl();
      case AppEnvironment.staging:
        return _stagingApiBaseUrl;
      case AppEnvironment.prod:
        return _prodApiBaseUrl;
    }
  }

  static String _devFallbackBaseUrl() {
    if (kIsWeb) return _devDefaultApiBaseUrl;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _devAndroidEmulatorApiBaseUrl;
      case TargetPlatform.iOS:
        return _devIosSimulatorApiBaseUrl;
      default:
        return _devDefaultApiBaseUrl;
    }
  }

  static String _platformOverride() {
    if (kIsWeb) {
      return _webBaseUrlFromEnv.trim();
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _androidBaseUrlFromEnv.trim();
      case TargetPlatform.iOS:
        return _iosBaseUrlFromEnv.trim();
      case TargetPlatform.windows:
        return _windowsBaseUrlFromEnv.trim();
      default:
        return '';
    }
  }

  static bool _isHttps(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && uri.scheme.toLowerCase() == 'https';
  }

  static String _normalizePin(String pin) {
    return pin.trim().toLowerCase().replaceAll(':', '').replaceAll(' ', '');
  }
}

enum AppEnvironment { dev, staging, prod }
