import 'package:dio/dio.dart';

import '../models/inventory_item_model.dart';

class InventoryRepository {
  InventoryRepository(this._dio);

  final Dio _dio;

  Future<List<InventoryItemModel>> readAll() async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/inventory');
      final payload = response.data ?? const [];

      return payload
          .whereType<Map<String, dynamic>>()
          .map(InventoryItemModel.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const [];
      }
      rethrow;
    }
  }

  Future<InventoryItemModel> readById(int itemId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/inventory/$itemId',
    );
    return InventoryItemModel.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<InventoryItemModel> updateStatus({
    required int itemId,
    required bool active,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/inventory/$itemId',
      data: {'active': active},
    );

    return InventoryItemModel.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<List<InventoryItemModel>> adminReadAll() async {
    final response = await _dio.get<List<dynamic>>(
      '/api/inventory/admin/inventories',
    );
    final payload = response.data ?? const [];

    return payload
        .whereType<Map<String, dynamic>>()
        .map(InventoryItemModel.fromJson)
        .toList(growable: false);
  }

  Future<InventoryItemModel> adminCreate({
    required int userId,
    required int articleId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/inventory/admin/',
      data: {'user_id': userId, 'article_id': articleId},
    );

    return InventoryItemModel.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<InventoryItemModel> adminUpdate({
    required int itemId,
    required int userId,
    required int articleId,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/inventory/admin/$itemId',
      data: {'user_id': userId, 'article_id': articleId},
    );

    return InventoryItemModel.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<void> adminDelete(int itemId) async {
    await _dio.delete<void>('/api/inventory/admin/$itemId');
  }
}
