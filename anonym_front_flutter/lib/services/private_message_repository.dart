import 'package:dio/dio.dart';

import '../models/channel_message_model.dart';

/// Repository HTTP pour les messages privés et pièces jointes.
class PrivateMessageRepository {
  PrivateMessageRepository(this._dio);

  final Dio _dio;

  Future<ChannelMessageModel> sendWithImage({
    required int channelId,
    String content = '',
    String? imageFilePath,
    List<int>? imageBytes,
    String? imageFileName,
  }) async {
    final formData = FormData();

    if (content.trim().isNotEmpty) {
      formData.fields.add(MapEntry('content', content.trim()));
    }

    if (imageFilePath != null && imageFilePath.isNotEmpty) {
      formData.files.add(
        MapEntry(
          'image',
          await MultipartFile.fromFile(
            imageFilePath,
            filename: imageFileName ?? imageFilePath.split('/').last,
          ),
        ),
      );
    } else if (imageBytes != null) {
      formData.files.add(
        MapEntry(
          'image',
          MultipartFile.fromBytes(
            imageBytes,
            filename: imageFileName ?? 'image.jpg',
          ),
        ),
      );
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '/api/privateMessage/$channelId/send',
      data: formData,
    );

    return ChannelMessageModel.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<ChannelMessageModel> update({
    required int messageId,
    required String content,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/privateMessage/$messageId',
      data: {'content': content},
    );

    return ChannelMessageModel.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<void> delete(int messageId) async {
    await _dio.delete<void>('/api/privateMessage/$messageId');
  }
}
