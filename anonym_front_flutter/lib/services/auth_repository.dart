import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../utils/app_logger.dart';
import 'api_client.dart';

/// Repository HTTP pour les flux d'authentification.
class AuthRepository {
  AuthRepository(this._dio, this._apiClient);

  final Dio _dio;
  final ApiClient _apiClient;

  Future<void> hydrateSession() async {
    final cookieHeaders = await _apiClient.buildSocketAuthHeaders();
    final hasLocalSessionCookie =
        cookieHeaders['Cookie'] is String &&
        (cookieHeaders['Cookie'] as String).trim().isNotEmpty;

    if (!hasLocalSessionCookie) {
      AppLogger.debug(
        '[AUTH][hydrateSession] skip refresh (no local session cookie)',
      );
      return;
    }

    final refreshed = await _apiClient.refreshSession();
    AppLogger.debug('[AUTH][hydrateSession] refresh attempted=$refreshed');
  }

  void setSessionExpiredHandler(VoidCallback handler) {
    _apiClient.setSessionExpiredHandler(handler);
  }

  Future<UserModel> login({
    required String identifier,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/login',
      data: {'identifier': identifier, 'password': password},
    );

    final payload = response.data ?? <String, dynamic>{};

    final userJson = payload['user'] is Map<String, dynamic>
        ? payload['user'] as Map<String, dynamic>
        : payload;

    return UserModel.fromJson(userJson);
  }

  Future<UserModel> signup({
    required String username,
    required String email,
    required String password,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/auth/signup',
      data: {'username': username, 'email': email, 'password': password},
    );

    // Le backend ne crée pas toujours de session à l'inscription,
    // on enchaine donc un login pour garantir la persistance.
    return login(identifier: email, password: password);
  }

  Future<Map<String, dynamic>> requestRegisterCode({
    required String email,
    required String username,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    final normalizedUsername = username.trim();
    final normalizedPassword = password.trim();

    if (normalizedEmail.isEmpty) {
      throw ArgumentError.value(email, 'email', 'E-mail est obligatoire');
    }
    if (normalizedUsername.isEmpty) {
      throw ArgumentError.value(
        username,
        'username',
        'Le pseudo est obligatoire',
      );
    }
    if (normalizedPassword.isEmpty) {
      throw ArgumentError.value(
        password,
        'password',
        'Le mot de passe est obligatoire',
      );
    }

    final requestBody = <String, dynamic>{
      'email': normalizedEmail,
      'username': normalizedUsername,
      'password': normalizedPassword,
    };
    AppLogger.debug(
      '[API][POST] /api/auth/register/request-code '
      'hasEmail=${normalizedEmail.isNotEmpty} hasUsername=${normalizedUsername.isNotEmpty} hasPassword=${normalizedPassword.isNotEmpty}',
    );
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/register/request-code',
      data: requestBody,
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<UserModel> confirmRegister({
    required String email,
    required String code,
  }) async {
    final requestBody = {'email': email, 'code': code};
    AppLogger.debug(
      '[API][POST] /api/auth/register/confirm hasEmail=${email.trim().isNotEmpty} hasCode=${code.trim().isNotEmpty}',
    );

    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/register/confirm',
      data: requestBody,
    );

    final payload = response.data ?? <String, dynamic>{};

    final userJson = payload['user'] is Map<String, dynamic>
        ? payload['user'] as Map<String, dynamic>
        : payload;
    return UserModel.fromJson(userJson);
  }

  Future<void> requestPasswordReset({required String email}) async {
    await _dio.post<void>('/api/auth/reset-password', data: {'email': email});
  }

  Future<void> completePasswordReset({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    await _dio.post<void>(
      '/api/auth/reset',
      data: {
        'token': token,
        'password': password,
        'confirmPassword': confirmPassword,
      },
    );
  }

  Future<UserModel> me() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/account');
    return UserModel.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<void> logout() async {
    try {
      await _dio.post<void>('/api/auth/logout');
    } finally {
      await clearLocalSession();
    }
  }

  Future<void> clearLocalSession() async {
    await _apiClient.clearSessionData();
  }
}
