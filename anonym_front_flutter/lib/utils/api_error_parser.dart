import 'package:dio/dio.dart';

import 'app_config.dart';

/// Utilitaire de normalisation des erreurs API vers un message lisible.
abstract final class ApiErrorParser {
  /// Extrait un message pertinent depuis [error] ou retourne [fallback].
  static String parse(
    Object error, {
    required String fallback,
    bool? exposeBackendDetails,
  }) {
    if (error is! DioException) {
      return fallback;
    }

    final shouldExpose = exposeBackendDetails ?? AppConfig.exposeBackendErrors;
    if (shouldExpose) {
      final detailed = _extractDetailedMessage(error);
      if (detailed != null) return detailed;
      return fallback;
    }

    final code = error.response?.statusCode ?? 0;
    if (code == 401) return 'Authentification echouee.';
    if (code == 403) return 'Acces refuse.';
    if (code == 429) return 'Trop de tentatives. Reessayez plus tard.';
    if (code >= 500) return 'Service temporairement indisponible.';

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.badCertificate) {
      return 'Connexion au serveur impossible.';
    }

    return fallback;
  }

  static String? _extractDetailedMessage(DioException error) {
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
    return null;
  }
}
