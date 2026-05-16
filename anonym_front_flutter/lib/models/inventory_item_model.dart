import 'shop_item_model.dart';

class InventoryItemModel {
  const InventoryItemModel({
    required this.itemId,
    required this.userId,
    required this.articleId,
    required this.active,
    this.createdAt,
    this.shop,
  });

  final int itemId;
  final int userId;
  final int articleId;
  final bool active;
  final DateTime? createdAt;
  final ShopItemModel? shop;

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    final shopJson = json['Shop'] ?? json['shop'];

    return InventoryItemModel(
      itemId: _toInt(json['item_id'] ?? json['itemId']),
      userId: _toInt(json['user_id'] ?? json['userId']),
      articleId: _toInt(json['article_id'] ?? json['articleId']),
      active: _toBool(json['active']),
      createdAt: _toDateTime(json['createdAt'] ?? json['created_at']),
      shop: shopJson is Map<String, dynamic>
          ? ShopItemModel.fromJson(shopJson)
          : null,
    );
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static bool _toBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  static DateTime? _toDateTime(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal();
    }
    return null;
  }
}
