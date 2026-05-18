import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../models/user_model.dart';

class AccountRepository {
  AccountRepository(this._dio);

  final Dio _dio;

  Future<UserModel> readAccount() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/account');
    return UserModel.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<List<UserModel>> readAllUsers() async {
    final response = await _dio.get<List<dynamic>>('/api/account/users');
    final payload = response.data ?? const [];

    return payload
        .whereType<Map<String, dynamic>>()
        .map(UserModel.fromJson)
        .toList(growable: false);
  }

  Future<UserModel> readUserById(int id) async {
    final response = await _dio.get<Map<String, dynamic>>('/api/account/$id');
    return UserModel.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<UserModel> updateProfile({
    required String username,
    required String email,
    String? bio,
    bool? allowNonFriendDms,
    String? avatarFilePath,
    Uint8List? avatarBytes,
    String? avatarFileName,
    bool deleteAvatar = false,
  }) async {
    final datas = <String, dynamic>{
      'username': username,
      'email': email,
      'bio': bio,
      if (allowNonFriendDms != null) 'allow_non_friend_dms': allowNonFriendDms,
      if (deleteAvatar) 'avatar': 'delete',
    };

    final formData = FormData.fromMap({
      'datas': jsonEncode(datas),
      if (avatarFilePath != null)
        'image': await MultipartFile.fromFile(avatarFilePath)
      else if (avatarBytes != null)
        'image': MultipartFile.fromBytes(
          avatarBytes,
          filename: avatarFileName ?? 'avatar.jpg',
        ),
    });

    final response = await _dio.put<Map<String, dynamic>>(
      '/api/account/update',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return UserModel.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    await _dio.put<void>(
      '/api/account/password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      },
    );
  }

  Future<void> deleteAccount() async {
    await _dio.delete<void>('/api/account/delete');
  }
}
