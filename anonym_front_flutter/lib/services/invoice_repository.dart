import 'package:dio/dio.dart';

import '../models/invoice_model.dart';

class InvoiceRepository {
  InvoiceRepository(this._dio);

  final Dio _dio;

  Future<List<InvoiceModel>> readAll() async {
    final response = await _dio.get<List<dynamic>>('/api/invoice');
    final payload = response.data ?? const [];

    return payload
        .whereType<Map<String, dynamic>>()
        .map(InvoiceModel.fromJson)
        .toList(growable: false);
  }

  Future<String> sendInvoiceByEmail(int invoiceId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/invoice/$invoiceId',
    );
    final payload = response.data ?? <String, dynamic>{};
    return (payload['message'] ?? 'Facture envoyee').toString();
  }

  Future<List<InvoiceModel>> adminReadAll() async {
    final response = await _dio.get<List<dynamic>>('/api/invoice/admin/');
    final payload = response.data ?? const [];

    return payload
        .whereType<Map<String, dynamic>>()
        .map(InvoiceModel.fromJson)
        .toList(growable: false);
  }

  Future<InvoiceModel> adminCreate({
    required int userId,
    required int articleId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/invoice/admin/',
      data: {'user_id': userId, 'article_id': articleId},
    );

    final payload = response.data ?? <String, dynamic>{};
    final invoiceJson = payload['invoice'] is Map<String, dynamic>
        ? payload['invoice'] as Map<String, dynamic>
        : payload;

    return InvoiceModel.fromJson(invoiceJson);
  }

  Future<InvoiceModel> adminUpdate({
    required int invoiceId,
    int? userId,
    int? articleId,
    int? quantity,
  }) async {
    final data = <String, dynamic>{
      'user_id': userId,
      'article_id': articleId,
      'quantity': quantity,
    }..removeWhere((key, value) => value == null);

    final response = await _dio.put<Map<String, dynamic>>(
      '/api/invoice/admin/$invoiceId',
      data: data,
    );

    final payload = response.data ?? <String, dynamic>{};
    final invoiceJson = payload['invoice'] is Map<String, dynamic>
        ? payload['invoice'] as Map<String, dynamic>
        : payload;

    return InvoiceModel.fromJson(invoiceJson);
  }

  Future<void> adminDelete(int invoiceId) async {
    await _dio.delete<void>('/api/invoice/admin/$invoiceId');
  }
}
