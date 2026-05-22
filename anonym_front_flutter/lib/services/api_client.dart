import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';

import '../utils/app_config.dart';

class ApiClient {
  ApiClient({
    CookieJar? cookieJar,
  }) : _cookieJar = cookieJar ?? CookieJar(),
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

  final Dio dio;
  final CookieJar _cookieJar;
  late final Dio _refreshDio;
  Completer<bool>? _refreshCompleter;
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

        final refreshed = await _refreshOrWait();
        if (!refreshed) {
          handler.next(error);
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

  Future<bool> _refreshOrWait() async {
    final pending = _refreshCompleter;
    if (pending != null) {
      return pending.future;
    }

    final completer = Completer<bool>();
    _refreshCompleter = completer;
    try {
      final ok = await _performRefreshRequest();
      completer.complete(ok);
      return ok;
    } catch (_) {
      completer.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<bool> _performRefreshRequest() async {
    try {
      final uri = Uri.parse(
        _refreshDio.options.baseUrl,
      ).replace(path: '/api/auth/refresh');
      final csrfToken = await _readCsrfToken(uri);
      final headers = <String, dynamic>{};
      if (csrfToken != null && csrfToken.isNotEmpty) {
        headers['X-CSRF-Token'] = csrfToken;
      }
      await _refreshDio.post<void>(
        '/api/auth/refresh',
        options: Options(
          headers: headers,
          extra: const {
            'withCredentials': true,
            'skipAuthRefresh': true,
          },
        ),
      );
      return true;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) {
        _onSessionExpired?.call();
      }
      return false;
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
