import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/user_model.dart';

class AdminRepository {
  AdminRepository(this._dio);

  final Dio _dio;

  Future<UserModel> createUser({
    required Map<String, dynamic> datas,
    String? avatarFilePath,
  }) async {
    final formData = FormData.fromMap({
      'datas': jsonEncode(datas),
      if (avatarFilePath != null)
        'image': await MultipartFile.fromFile(avatarFilePath),
    });

    final response = await _dio.post<Map<String, dynamic>>(
      '/api/admin/users',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return UserModel.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<UserModel> updateUser({
    required int userId,
    required Map<String, dynamic> datas,
    String? avatarFilePath,
  }) async {
    final formData = FormData.fromMap({
      'datas': jsonEncode(datas),
      if (avatarFilePath != null)
        'image': await MultipartFile.fromFile(avatarFilePath),
    });

    final response = await _dio.put<Map<String, dynamic>>(
      '/api/admin/users/$userId',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return UserModel.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<void> deleteUser(int userId) async {
    await _dio.delete<void>('/api/admin/users/$userId');
  }

  Future<void> report({
    required String email,
    required String type,
    required String content,
  }) async {
    await _dio.post<void>(
      '/api/admin/report',
      data: {'email': email, 'type': type, 'content': content},
    );
  }

  String apiDocsPath() {
    return '/api/admin/api-docs';
  }
}
