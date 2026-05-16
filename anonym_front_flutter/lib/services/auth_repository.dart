import 'package:dio/dio.dart';

import '../models/user_model.dart';
import 'api_client.dart';
import 'session_service.dart';

class AuthRepository {
  AuthRepository(this._dio, this._apiClient, this._sessionService);

  final Dio _dio;
  final ApiClient _apiClient;
  final SessionService _sessionService;

  Future<void> hydrateSession() async {
    final token = await _sessionService.readToken();
    _apiClient.setAuthToken(token);
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
    final token = payload['token']?.toString();

    if (token != null && token.isNotEmpty) {
      await _sessionService.saveToken(token);
      _apiClient.setAuthToken(token);
    }

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

  Future<void> requestPasswordReset({required String email}) async {
    await _dio.post<void>('/api/auth/reset-password', data: {'email': email});
  }

  Future<void> completePasswordReset({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    await _dio.post<void>(
      '/api/auth/reset?token=$token',
      data: {'password': password, 'confirmPassword': confirmPassword},
    );
  }

  Future<UserModel> me() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/account');
    return UserModel.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<void> logout() async {
    await _dio.post<void>('/api/auth/logout');
    await clearLocalSession();
  }

  Future<void> clearLocalSession() async {
    _apiClient.setAuthToken(null);
    await _sessionService.clearToken();
  }
}
