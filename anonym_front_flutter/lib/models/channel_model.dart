import '../utils/media_url.dart';

class ChannelModel {
  const ChannelModel({
    required this.channelId,
    required this.name,
    this.description,
    required this.createdBy,
    this.unreadCount = 0,
    this.channelType = 'GROUP',
    this.visibility = 'PUBLIC',
    this.coverImage,
  });

  final int channelId;
  final String name;
  final String? description;
  final int createdBy;
  final int unreadCount;
  final String channelType;
  final String visibility;
  final String? coverImage;

  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    return ChannelModel(
      channelId: _toInt(json['channel_id'] ?? json['channelId']),
      name: (json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      createdBy: _toInt(json['created_by'] ?? json['createdBy']),
      unreadCount: _toInt(json['unreadCount'] ?? json['count']),
      channelType: (json['channel_type'] ?? json['channelType'] ?? 'GROUP')
          .toString(),
      visibility: (json['visibility'] ?? 'PUBLIC').toString(),
      coverImage: MediaUrl.nullable(
        (json['cover_image'] ?? json['coverImage'])?.toString(),
      ),
    );
  }

  ChannelModel copyWith({
    int? channelId,
    String? name,
    String? description,
    int? createdBy,
    int? unreadCount,
    String? channelType,
    String? visibility,
    String? coverImage,
  }) {
    return ChannelModel(
      channelId: channelId ?? this.channelId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      unreadCount: unreadCount ?? this.unreadCount,
      channelType: channelType ?? this.channelType,
      visibility: visibility ?? this.visibility,
      coverImage: coverImage ?? this.coverImage,
    );
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
