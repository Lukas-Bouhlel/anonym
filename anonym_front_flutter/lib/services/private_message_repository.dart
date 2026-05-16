import 'package:dio/dio.dart';

import '../models/channel_message_model.dart';

class PrivateMessageRepository {
  PrivateMessageRepository(this._dio);

  final Dio _dio;

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
