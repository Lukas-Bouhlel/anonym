enum AppNotificationType { newMessage, friendRequest }

class AppNotificationModel {
  const AppNotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.createdAt,
    this.avatarUrl,
    this.relatedUserId,
    this.relatedChannelId,
    this.isRead = false,
  });

  final String id;
  final AppNotificationType type;
  final String title;
  final String subtitle;
  final DateTime createdAt;
  final String? avatarUrl;
  final int? relatedUserId;
  final int? relatedChannelId;
  final bool isRead;

  AppNotificationModel copyWith({bool? isRead}) {
    return AppNotificationModel(
      id: id,
      type: type,
      title: title,
      subtitle: subtitle,
      createdAt: createdAt,
      avatarUrl: avatarUrl,
      relatedUserId: relatedUserId,
      relatedChannelId: relatedChannelId,
      isRead: isRead ?? this.isRead,
    );
  }
}
