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
    Future<ChannelModel> postJson({required String endpoint}) async {
      final payload = <String, dynamic>{
        'channelType': channelType,
        'name': ?name,
        'description': ?description,
        'visibility': ?visibility,
        if (memberIds != null) 'memberIds': memberIds,
      };
      final response = await _dio.post<Map<String, dynamic>>(
        endpoint,
        data: payload,
      );
      return ChannelModel.fromJson(response.data ?? <String, dynamic>{});
    }

    Future<ChannelModel> postForm({
      required String endpoint,
      String? imagePath,
    }) async {
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
        endpoint,
        data: FormData.fromMap(payload),
        options: Options(contentType: 'multipart/form-data'),
      );
      return ChannelModel.fromJson(response.data ?? <String, dynamic>{});
    }

    final hasImage = imageFilePath != null && imageFilePath.trim().isNotEmpty;
    final useMultipart = hasImage;

    try {
      if (useMultipart) {
        return await postForm(
          endpoint: '/api/channels',
          imagePath: imageFilePath,
        );
      }
      return await postJson(endpoint: '/api/channels');
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode == 404 || statusCode == 405) {
        if (useMultipart) {
          return postForm(endpoint: '/api/channel', imagePath: imageFilePath);
        }
        return postJson(endpoint: '/api/channel');
      }

      final message = e.response?.data?.toString().toLowerCase() ?? '';
      final canRetryWithoutImage =
          imageFilePath != null &&
          imageFilePath.trim().isNotEmpty &&
          message.contains('cover_image');
      if (!canRetryWithoutImage) rethrow;
      return postJson(endpoint: '/api/channels');
    }
  }

  Future<void> invite({required int channelId, required int userId}) async {
    try {
      await _dio.post<void>(
        '/api/channels/invite',
        data: {'channelId': channelId, 'userId': userId},
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode != 404 && statusCode != 405) rethrow;
      await _dio.post<void>(
        '/api/channel/invite',
        data: {'channelId': channelId, 'userId': userId},
      );
    }
  }

  Future<List<ChannelModel>> readUserChannels({String? filter}) async {
    List<dynamic>? payload;
    final query = <String, dynamic>{};
    if (filter != null && filter.trim().isNotEmpty) {
      query['filter'] = filter.trim().toLowerCase();
    }
    try {
      final response = await _dio.get<List<dynamic>>(
        '/api/channels/user',
        queryParameters: query.isEmpty ? null : query,
      );
      payload = response.data;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode != 404 && statusCode != 405) rethrow;
      final legacyResponse = await _dio.get<List<dynamic>>(
        '/api/channel/user',
        queryParameters: query.isEmpty ? null : query,
      );
      payload = legacyResponse.data;
    }
    final normalized = payload ?? const [];

    return normalized
        .whereType<Map<String, dynamic>>()
        .map(ChannelModel.fromJson)
        .toList(growable: false);
  }

  Future<List<ChannelModel>> readPublicChannels() async {
    try {
      return await readUserChannels(filter: 'all');
    } on DioException {
      List<dynamic>? payload;
      try {
        final response = await _dio.get<List<dynamic>>('/api/channels/public');
        payload = response.data;
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode ?? 0;
        if (statusCode != 404 && statusCode != 405) rethrow;
        final legacyResponse = await _dio.get<List<dynamic>>(
          '/api/channel/public',
        );
        payload = legacyResponse.data;
      }
      final normalized = payload ?? const [];
      return normalized
          .whereType<Map<String, dynamic>>()
          .map(ChannelModel.fromJson)
          .toList(growable: false);
    }
  }

  Future<int> readUnreadCount(int channelId) async {
    Map<String, dynamic>? payload;
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/channels/$channelId/unreadCount',
      );
      payload = response.data;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode != 404 && statusCode != 405) rethrow;
      final legacyResponse = await _dio.get<Map<String, dynamic>>(
        '/api/channel/$channelId/unreadCount',
      );
      payload = legacyResponse.data;
    }
    final normalized = payload ?? <String, dynamic>{};
    return _toInt(normalized['count']);
  }

  Future<List<UserModel>> readChannelUsers(int channelId) async {
    List<dynamic>? payload;
    try {
      final response = await _dio.get<List<dynamic>>(
        '/api/channels/$channelId/users',
      );
      payload = response.data;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode != 404 && statusCode != 405) rethrow;
      final legacyResponse = await _dio.get<List<dynamic>>(
        '/api/channel/$channelId/users',
      );
      payload = legacyResponse.data;
    }
    final normalized = payload ?? const [];

    return normalized
        .whereType<Map<String, dynamic>>()
        .map(UserModel.fromJson)
        .toList(growable: false);
  }

  Future<List<ChannelMessageModel>> readChannelMessages(int channelId) async {
    dynamic payload;
    try {
      final response = await _dio.get<dynamic>(
        '/api/channels/$channelId/messages',
      );
      payload = response.data;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode != 404 && statusCode != 405) rethrow;
      final legacyResponse = await _dio.get<dynamic>(
        '/api/channel/$channelId/messages',
      );
      payload = legacyResponse.data;
    }

    if (payload is! List) {
      return const [];
    }

    return payload
        .whereType<Map<String, dynamic>>()
        .map(ChannelMessageModel.fromJson)
        .toList(growable: false);
  }

  Future<void> leaveChannel(int channelId) async {
    try {
      await _dio.delete<void>('/api/channels/leave/$channelId');
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode != 404 && statusCode != 405) rethrow;
      await _dio.delete<void>('/api/channel/leave/$channelId');
    }
  }

  Future<void> deleteChannel(int channelId) async {
    try {
      await _dio.delete<void>('/api/channels/$channelId');
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode != 404 && statusCode != 405) rethrow;
      await _dio.delete<void>('/api/channel/$channelId');
    }
  }

  Future<void> joinPublic(int channelId) async {
    try {
      await _dio.post<void>('/api/channels/$channelId/join-public', data: {});
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode != 404 && statusCode != 405) rethrow;
      await _dio.post<void>('/api/channel/$channelId/join-public', data: {});
    }
  }

  Future<void> updateCover({
    required int channelId,
    required String imageFilePath,
  }) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imageFilePath),
    });
    try {
      await _dio.put<void>(
        '/api/channels/$channelId/cover',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode != 404 && statusCode != 405) rethrow;
      await _dio.put<void>(
        '/api/channel/$channelId/cover',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    }
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
      try {
        await _dio.patch<void>('/api/channels/$channelId', data: payload);
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode ?? 0;
        if (statusCode != 404 && statusCode != 405) rethrow;
        try {
          await _dio.put<void>('/api/channel/$channelId', data: payload);
        } on DioException {
          await _dio.patch<void>('/api/channel/$channelId', data: payload);
        }
      }
    }
  }

  Future<int> joinByInvite(String code) async {
    Map<String, dynamic>? payload;
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/channels/join-by-invite',
        data: {'code': code},
      );
      payload = response.data;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode != 404 && statusCode != 405) rethrow;
      final legacyResponse = await _dio.post<Map<String, dynamic>>(
        '/api/channel/join-by-invite',
        data: {'code': code},
      );
      payload = legacyResponse.data;
    }
    final normalized = payload ?? const <String, dynamic>{};
    return _toInt(normalized['channel_id']);
  }

  Future<Map<String, dynamic>> createInviteLink({
    required int channelId,
    required String mode,
    int? expiresInMinutes,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/channels/$channelId/invite-links',
        data: {'mode': mode, 'expiresInMinutes': ?expiresInMinutes},
      );
      return response.data ?? const <String, dynamic>{};
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode != 404 && statusCode != 405) rethrow;
      final legacyResponse = await _dio.post<Map<String, dynamic>>(
        '/api/channel/$channelId/invite-links',
        data: {'mode': mode, 'expiresInMinutes': ?expiresInMinutes},
      );
      return legacyResponse.data ?? const <String, dynamic>{};
    }
  }

  int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
