import 'package:dio/dio.dart';

class ApiErrorParser {
  const ApiErrorParser._();

  static String parse(Object error, {required String fallback}) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
        if (message is List && message.isNotEmpty) {
          return message.join('\n');
        }
      }

      if (data is String && data.trim().isNotEmpty) {
        return data;
      }

      if (error.message != null && error.message!.trim().isNotEmpty) {
        return error.message!;
      }
    }

    return fallback;
  }
}
