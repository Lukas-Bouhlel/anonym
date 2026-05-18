import 'package:dio/dio.dart';
import 'dart:convert';

import '../models/channel_message_model.dart';
import '../models/channel_model.dart';
import '../models/user_model.dart';

class ChannelRepository {
  ChannelRepository(this._dio);

  final Dio _dio;

  Future<ChannelModel> create({
    required String channelType,
    String? name,
    String? description,
    String? visibility,
    List<int>? memberIds,
    String? imageFilePath,
  }) async {
    Future<ChannelModel> postForm({String? imagePath}) async {
      final payload = <String, dynamic>{
        'channelType': channelType,
        'name': ?name,
        'description': ?description,
        'visibility': ?visibility,
        if (memberIds != null) 'memberIds': jsonEncode(memberIds),
        if (imagePath != null && imagePath.trim().isNotEmpty) ...{
          'image': await MultipartFile.fromFile(imagePath),
          // Compat backend: certains environnements attendent explicitement cover_image.
          'cover_image': await MultipartFile.fromFile(imagePath),
        },
      };
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/channels',
        data: FormData.fromMap(payload),
        options: Options(contentType: 'multipart/form-data'),
      );
      return ChannelModel.fromJson(response.data ?? <String, dynamic>{});
    }

    try {
      return await postForm(imagePath: imageFilePath);
    } on DioException catch (e) {
      final message = e.response?.data?.toString().toLowerCase() ?? '';
      final canRetryWithoutImage =
          imageFilePath != null &&
          imageFilePath.trim().isNotEmpty &&
          message.contains('cover_image');
      if (!canRetryWithoutImage) rethrow;
      return postForm();
    }
  }

  Future<void> invite({required int channelId, required int userId}) async {
    await _dio.post<void>(
      '/api/channels/invite',
      data: {'channelId': channelId, 'userId': userId},
    );
  }

  Future<List<ChannelModel>> readUserChannels() async {
    final response = await _dio.get<List<dynamic>>('/api/channels/user');
    final payload = response.data ?? const [];

    return payload
        .whereType<Map<String, dynamic>>()
        .map(ChannelModel.fromJson)
        .toList(growable: false);
  }

  Future<int> readUnreadCount(int channelId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/channels/$channelId/unreadCount',
    );
    final payload = response.data ?? <String, dynamic>{};
    return _toInt(payload['count']);
  }

  Future<List<UserModel>> readChannelUsers(int channelId) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/channels/$channelId/users',
    );
    final payload = response.data ?? const [];

    return payload
        .whereType<Map<String, dynamic>>()
        .map(UserModel.fromJson)
        .toList(growable: false);
  }

  Future<List<ChannelMessageModel>> readChannelMessages(int channelId) async {
    final response = await _dio.get<dynamic>(
      '/api/channels/$channelId/messages',
    );
    final payload = response.data;

    if (payload is! List) {
      return const [];
    }

    return payload
        .whereType<Map<String, dynamic>>()
        .map(ChannelMessageModel.fromJson)
        .toList(growable: false);
  }

  Future<void> leaveChannel(int channelId) async {
    await _dio.delete<void>('/api/channels/leave/$channelId');
  }

  Future<void> deleteChannel(int channelId) async {
    await _dio.delete<void>('/api/channels/$channelId');
  }

  Future<void> joinPublic(int channelId) async {
    await _dio.post<void>('/api/channels/$channelId/join-public', data: {});
  }

  Future<void> updateCover({
    required int channelId,
    required String imageFilePath,
  }) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imageFilePath),
    });
    await _dio.put<void>(
      '/api/channels/$channelId/cover',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  Future<void> updateGroup({
    required int channelId,
    String? name,
    String? description,
    String? visibility,
  }) async {
    final payload = <String, dynamic>{
      'name': ?name,
      'description': ?description,
      'visibility': ?visibility,
    };
    if (payload.isEmpty) return;
    try {
      await _dio.put<void>('/api/channels/$channelId', data: payload);
    } on DioException {
      await _dio.patch<void>('/api/channels/$channelId', data: payload);
    }
  }

  Future<int> joinByInvite(String code) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/channels/join-by-invite',
      data: {'code': code},
    );
    final payload = response.data ?? const <String, dynamic>{};
    return _toInt(payload['channel_id']);
  }

  Future<Map<String, dynamic>> createInviteLink({
    required int channelId,
    required String mode,
    int? expiresInMinutes,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/channels/$channelId/invite-links',
      data: {
        'mode': mode,
        'expiresInMinutes': ?expiresInMinutes,
      },
    );
    return response.data ?? const <String, dynamic>{};
  }

  int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
