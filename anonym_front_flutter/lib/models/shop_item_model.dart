import '../utils/media_url.dart';

class ShopItemModel {
  const ShopItemModel({
    required this.articleId,
    required this.title,
    required this.type,
    required this.amount,
    required this.content,
  });

  final int articleId;
  final String title;
  final String type;
  final int amount;
  final String content;

  factory ShopItemModel.fromJson(Map<String, dynamic> json) {
    return ShopItemModel(
      articleId: _toInt(json['article_id'] ?? json['articleId']),
      title: (json['title'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      amount: _toInt(json['amount']),
      content: MediaUrl.normalize((json['content'] ?? '').toString()),
    );
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
