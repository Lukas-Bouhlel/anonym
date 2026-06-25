import 'user_model.dart';

/// Modèle représentant un message de conversation.
class ChannelMessageModel {
  const ChannelMessageModel({
    required this.messageId,
    required this.content,
    required this.channelId,
    this.senderId,
    this.status,
    this.createdAt,
    this.sender,
    this.imageUrl,
  });

  final int messageId;
  final String content;
  final int channelId;
  final int? senderId;
  final String? status;
  final DateTime? createdAt;
  final UserModel? sender;
  final String? imageUrl;

  /// Construit un message depuis une réponse JSON backend.
  ///
  /// Cette factory accepte plusieurs variantes de clés pour rester robuste
  /// face aux différences de format entre endpoints.
  factory ChannelMessageModel.fromJson(Map<String, dynamic> json) {
    final senderJson =
        json['User'] ?? json['user'] ?? json['Sender'] ?? json['sender'];
    final sender = senderJson is Map<String, dynamic>
        ? UserModel.fromJson(senderJson)
        : null;

    return ChannelMessageModel(
      messageId: _toInt(json['message_id'] ?? json['id'] ?? json['Id']),
      content: (json['content'] ?? json['Content'] ?? '').toString(),
      channelId: _toInt(
        json['channel_id'] ?? json['channelId'] ?? json['ChannelId'],
      ),
      senderId:
          _toNullableInt(
            json['sender_id'] ??
                json['senderId'] ??
                json['SenderId'] ??
                json['user_id'] ??
                json['userId'] ??
                json['UserId'] ??
                json['user_sender_id'] ??
                json['userSenderId'] ??
                json['UserSenderId'],
          ) ??
          sender?.id,
      status: json['status']?.toString(),
      createdAt: _parseDate(json['createdAt'] ?? json['CreatedAt']),
      sender: sender,
      imageUrl: json['imageUrl']?.toString() ??
          json['image_url']?.toString() ??
          json['ImageUrl']?.toString(),
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

  static int? _toNullableInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
