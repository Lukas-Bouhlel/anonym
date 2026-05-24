import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/payment_confirmation_model.dart';

class PaymentRepository {
  PaymentRepository(this._dio);

  final Dio _dio;

  Future<String> createCheckout(int articleId) async {
    final platform = kIsWeb ? 'web' : 'mobile';
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/payment',
      data: {'article_id': articleId, 'platform': platform},
    );

    final payload = response.data ?? <String, dynamic>{};
    return (payload['url'] ?? '').toString();
  }

  Future<PaymentConfirmationModel> confirm(String sessionId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/payment/confirm',
      queryParameters: {'session_id': sessionId},
    );

    return PaymentConfirmationModel.fromJson(
      response.data ?? <String, dynamic>{},
    );
  }
}
