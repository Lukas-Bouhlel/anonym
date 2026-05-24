import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/app_config.dart';

class ApiClient {
  ApiClient({CookieJar? cookieJar})
    : _cookieJar = cookieJar ?? CookieJar(),
      dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          headers: const {'Content-Type': 'application/json'},
          extra: const {'withCredentials': true},
        ),
      ) {
    dio.interceptors.add(CookieManager(_cookieJar));
    dio.interceptors.add(_buildAuthInterceptor());
    _refreshDio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: const {'Content-Type': 'application/json'},
        extra: const {'withCredentials': true},
      ),
    )..interceptors.add(CookieManager(_cookieJar));
  }

  static Future<ApiClient> create({CookieJar? cookieJar}) async {
    if (cookieJar != null) {
      return ApiClient(cookieJar: cookieJar);
    }

    if (kIsWeb) {
      return ApiClient(cookieJar: CookieJar());
    }

    final appDir = await getApplicationSupportDirectory();
    final storage = FileStorage('${appDir.path}/.cookies/');
    final persistentJar = PersistCookieJar(
      storage: storage,
      ignoreExpires: false,
    );
    return ApiClient(cookieJar: persistentJar);
  }

  final Dio dio;
  final CookieJar _cookieJar;
  late final Dio _refreshDio;
  Completer<_RefreshOutcome>? _refreshCompleter;
  VoidCallback? _onSessionExpired;

  static const Set<String> _csrfProtectedPaths = {
    '/api/auth/login',
    '/api/auth/refresh',
    '/api/auth/logout',
    '/api/auth/reset-password',
    '/api/auth/reset',
    '/api/auth/reset/',
  };

  void setSessionExpiredHandler(VoidCallback handler) {
    _onSessionExpired = handler;
  }

  @Deprecated('Auth token header flow replaced by cookie-based auth.')
  String? get authToken => _authToken;
  String? get _authToken => null;

  Future<void> clearSessionData() async {
    await _cookieJar.deleteAll();
  }

  Future<Map<String, dynamic>> buildSocketAuthHeaders() async {
    final uri = Uri.parse(AppConfig.apiBaseUrl);
    final cookies = await _cookieJar.loadForRequest(uri);
    if (cookies.isEmpty) return const <String, dynamic>{};
    final cookieHeader = cookies
        .map((cookie) => '${cookie.name}=${cookie.value}')
        .join('; ');
    if (cookieHeader.trim().isEmpty) return const <String, dynamic>{};
    return <String, dynamic>{'Cookie': cookieHeader};
  }

  Future<String?> buildSocketAuthToken() async {
    final uri = Uri.parse(AppConfig.apiBaseUrl);
    final cookies = await _cookieJar.loadForRequest(uri);
    for (final cookie in cookies) {
      if (cookie.name != 'token') continue;
      final value = cookie.value.trim();
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  Future<bool> refreshSession() async {
    final outcome = await _refreshOrWait();
    return outcome.refreshed;
  }

  Interceptor _buildAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_requiresCsrfHeader(options)) {
          final csrfToken = await _readCsrfToken(options.uri);
          if (csrfToken != null && csrfToken.isNotEmpty) {
            options.headers['X-CSRF-Token'] = csrfToken;
          }
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (!_shouldAttemptRefresh(error)) {
          handler.next(error);
          return;
        }

        final refreshOutcome = await _refreshOrWait();
        if (!refreshOutcome.refreshed) {
          if (refreshOutcome.authRejected) {
            handler.next(error);
            return;
          }
          handler.next(
            DioException(
              requestOptions: error.requestOptions,
              type: DioExceptionType.connectionError,
              error:
                  'Auth refresh unavailable (network/server). Session kept locally.',
            ),
          );
          return;
        }

        try {
          final request = error.requestOptions;
          request.extra['retriedWithRefresh'] = true;
          if (_requiresCsrfHeader(request)) {
            final csrfToken = await _readCsrfToken(request.uri);
            if (csrfToken != null && csrfToken.isNotEmpty) {
              request.headers['X-CSRF-Token'] = csrfToken;
            }
          }
          final response = await dio.fetch<dynamic>(request);
          handler.resolve(response);
        } catch (retryError) {
          handler.next(_asDioException(retryError, error.requestOptions));
        }
      },
    );
  }

  bool _requiresCsrfHeader(RequestOptions options) {
    if (options.method.toUpperCase() != 'POST') return false;
    return _csrfProtectedPaths.contains(_normalizePath(options.path));
  }

  bool _shouldAttemptRefresh(DioException error) {
    if (error.response?.statusCode != 401) return false;
    final request = error.requestOptions;
    if (request.extra['skipAuthRefresh'] == true) return false;
    if (request.extra['retriedWithRefresh'] == true) return false;
    final normalizedPath = _normalizePath(request.path);
    return normalizedPath != '/api/auth/refresh';
  }

  Future<_RefreshOutcome> _refreshOrWait() async {
    final pending = _refreshCompleter;
    if (pending != null) {
      return pending.future;
    }

    final completer = Completer<_RefreshOutcome>();
    _refreshCompleter = completer;
    try {
      final outcome = await _performRefreshRequest();
      completer.complete(outcome);
      return outcome;
    } catch (_) {
      const outcome = _RefreshOutcome.networkOrServerFailure();
      completer.complete(outcome);
      return outcome;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<_RefreshOutcome> _performRefreshRequest() async {
    try {
      final uri = Uri.parse(
        _refreshDio.options.baseUrl,
      ).replace(path: '/api/auth/refresh');
      Future<void> performRefreshRequest() async {
        final csrfToken = await _readCsrfToken(uri);
        final headers = <String, dynamic>{};
        if (csrfToken != null && csrfToken.isNotEmpty) {
          headers['X-CSRF-Token'] = csrfToken;
        }
        await _refreshDio.post<void>(
          '/api/auth/refresh',
          options: Options(
            headers: headers,
            extra: const {'withCredentials': true, 'skipAuthRefresh': true},
          ),
        );
      }

      try {
        await performRefreshRequest();
      } on DioException catch (refreshError) {
        if ((refreshError.response?.statusCode ?? 0) != 403) {
          rethrow;
        }

        // Re-prime CSRF cookie then retry once.
        try {
          await _refreshDio.get<void>(
            '/api/account',
            options: Options(
              extra: {'withCredentials': true, 'skipAuthRefresh': true},
            ),
          );
        } catch (_) {
          // Best-effort: route may still return 401, cookie can still be issued.
        }

        await performRefreshRequest();
      }

      return const _RefreshOutcome.refreshed();
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) {
        _onSessionExpired?.call();
        return const _RefreshOutcome.authRejected();
      }
      return const _RefreshOutcome.networkOrServerFailure();
    }
  }

  Future<String?> _readCsrfToken(Uri uri) async {
    final cookies = await _cookieJar.loadForRequest(uri);
    for (final cookie in cookies) {
      if (cookie.name == 'csrfToken') {
        final value = cookie.value.trim();
        if (value.isNotEmpty) return value;
      }
    }
    return null;
  }

  String _normalizePath(String rawPath) {
    if (rawPath.isEmpty) return rawPath;
    return Uri.parse(rawPath).path;
  }

  DioException _asDioException(Object error, RequestOptions requestOptions) {
    if (error is DioException) return error;
    return DioException(
      requestOptions: requestOptions,
      error: error,
      type: DioExceptionType.unknown,
    );
  }
}

class _RefreshOutcome {
  const _RefreshOutcome._({
    required this.refreshed,
    required this.authRejected,
  });

  const _RefreshOutcome.refreshed()
    : this._(refreshed: true, authRejected: false);

  const _RefreshOutcome.authRejected()
    : this._(refreshed: false, authRejected: true);

  const _RefreshOutcome.networkOrServerFailure()
    : this._(refreshed: false, authRejected: false);

  final bool refreshed;
  final bool authRejected;
}
