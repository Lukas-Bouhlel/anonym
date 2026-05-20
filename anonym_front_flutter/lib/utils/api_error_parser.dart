import 'package:dio/dio.dart';

class ApiErrorParser {
  const ApiErrorParser._();

  static String parse(Object error, {required String fallback}) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        for (final key in ['message', 'error', 'detail']) {
          final value = data[key];
          if (value is String && value.trim().isNotEmpty) {
            return value;
          }
          if (value is List && value.isNotEmpty) {
            return value.join('\n');
          }
        }

        final errors = data['errors'];
        if (errors is List && errors.isNotEmpty) {
          return errors.join('\n');
        }
        if (errors is Map) {
          final lines = <String>[];
          errors.forEach((field, value) {
            if (value is List && value.isNotEmpty) {
              lines.add(value.join('\n'));
            } else if (value is String && value.trim().isNotEmpty) {
              lines.add(value);
            }
          });
          if (lines.isNotEmpty) return lines.join('\n');
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
