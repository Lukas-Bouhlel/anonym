import '../utils/media_url.dart';
import 'user_model.dart';

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
    this.dmPeer,
    this.isJoined,
    this.listCategory,
  });

  final int channelId;
  final String name;
  final String? description;
  final int createdBy;
  final int unreadCount;
  final String channelType;
  final String visibility;
  final String? coverImage;
  final UserModel? dmPeer;
  final bool? isJoined;
  final String? listCategory;

  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    final rawDmPeer = json['dm_peer'] ?? json['dmPeer'];
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
      isJoined: _toBool(json['is_joined'] ?? json['isJoined']),
      listCategory: (json['list_category'] ?? json['listCategory'])
          ?.toString(),
      dmPeer: rawDmPeer is Map
          ? UserModel.fromJson(Map<String, dynamic>.from(rawDmPeer))
          : null,
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
    UserModel? dmPeer,
    bool? isJoined,
    String? listCategory,
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
      dmPeer: dmPeer ?? this.dmPeer,
      isJoined: isJoined ?? this.isJoined,
      listCategory: listCategory ?? this.listCategory,
    );
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static bool? _toBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return null;
  }
}
