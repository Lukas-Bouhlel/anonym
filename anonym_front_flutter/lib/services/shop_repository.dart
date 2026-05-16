import 'package:dio/dio.dart';
import 'dart:convert';

import '../models/shop_item_model.dart';

class ShopRepository {
  ShopRepository(this._dio);

  final Dio _dio;

  Future<List<ShopItemModel>> readAll() async {
    final response = await _dio.get<List<dynamic>>('/api/shop');
    final payload = response.data ?? const [];

    return payload
        .whereType<Map<String, dynamic>>()
        .map(ShopItemModel.fromJson)
        .toList(growable: false);
  }

  Future<ShopItemModel> readById(int articleId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/shop/$articleId',
    );
    return ShopItemModel.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<ShopItemModel> adminCreate({
    required Map<String, dynamic> datas,
    required String imageFilePath,
  }) async {
    final formData = FormData.fromMap({
      'datas': jsonEncode(datas),
      'image': await MultipartFile.fromFile(imageFilePath),
    });

    final response = await _dio.post<Map<String, dynamic>>(
      '/api/shop/admin/',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return ShopItemModel.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<ShopItemModel> adminUpdate({
    required int articleId,
    required Map<String, dynamic> datas,
    String? imageFilePath,
  }) async {
    final formData = FormData.fromMap({
      'datas': jsonEncode(datas),
      if (imageFilePath != null)
        'image': await MultipartFile.fromFile(imageFilePath),
    });

    final response = await _dio.put<Map<String, dynamic>>(
      '/api/shop/admin/$articleId',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return ShopItemModel.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<void> adminDelete(int articleId) async {
    await _dio.delete<void>('/api/shop/admin/$articleId');
  }
}
