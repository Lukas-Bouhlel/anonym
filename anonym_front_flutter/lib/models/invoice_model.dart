/// Représente une facture générée suite à un achat.
class InvoiceModel {
  const InvoiceModel({
    required this.id,
    required this.userId,
    required this.articleId,
    required this.type,
    required this.amount,
    required this.content,
    required this.quantity,
    this.createdAt,
  });

  final int id;
  final int userId;
  final int articleId;
  final String type;
  final int amount;
  final String content;
  final int quantity;
  final DateTime? createdAt;

  /// Construit une facture depuis un objet JSON.
  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: _toInt(json['id']),
      userId: _toInt(json['user_id'] ?? json['userId']),
      articleId: _toInt(json['article_id'] ?? json['articleId']),
      type: (json['type'] ?? '').toString(),
      amount: _toInt(json['amount']),
      content: (json['content'] ?? '').toString(),
      quantity: _toInt(json['quantity']),
      createdAt: _parseDate(json['createdAt']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
