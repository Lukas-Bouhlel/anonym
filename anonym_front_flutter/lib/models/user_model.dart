import 'inventory_item_model.dart';
import '../utils/media_url.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.level = 1,
    this.createdAt,
    this.avatar,
    this.bio,
    this.roles,
    this.presenceStatus,
    this.allowNonFriendDms = true,
    this.inventories = const [],
  });

  final int id;
  final String username;
  final String email;
  final int level;
  final DateTime? createdAt;
  final String? avatar;
  final String? bio;
  final String? roles;
  final String? presenceStatus;
  final bool allowNonFriendDms;
  final List<InventoryItemModel> inventories;

  bool get isAdmin => roles == 'ADMIN' || roles == 'SUPER_ADMIN';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _toInt(json['id'] ?? json['user_id'] ?? json['userId']),
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      level: _toLevel(json['level']),
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      avatar: MediaUrl.nullable(json['avatar']?.toString()),
      bio: json['bio']?.toString(),
      roles: json['roles']?.toString(),
      presenceStatus: json['presence_status']?.toString(),
      allowNonFriendDms: _toBool(
        json['allow_non_friend_dms'] ?? json['allowNonFriendDms'],
        fallback: true,
      ),
      inventories: _parseInventories(json),
    );
  }

  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    int? level,
    DateTime? createdAt,
    String? avatar,
    String? bio,
    String? roles,
    String? presenceStatus,
    bool? allowNonFriendDms,
    List<InventoryItemModel>? inventories,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      level: level ?? this.level,
      createdAt: createdAt ?? this.createdAt,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      roles: roles ?? this.roles,
      presenceStatus: presenceStatus ?? this.presenceStatus,
      allowNonFriendDms: allowNonFriendDms ?? this.allowNonFriendDms,
      inventories: inventories ?? this.inventories,
    );
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int _toLevel(Object? value) {
    final parsed = _toInt(value);
    return parsed <= 0 ? 1 : parsed;
  }

  static bool _toBool(Object? value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return fallback;
  }

  static List<InventoryItemModel> _parseInventories(Map<String, dynamic> json) {
    final raw =
        json['Inventories'] ??
        json['inventories'] ??
        json['Inventory'] ??
        json['inventory'];
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(InventoryItemModel.fromJson)
          .toList(growable: false);
    }
    if (raw is Map<String, dynamic>) {
      return [InventoryItemModel.fromJson(raw)];
    }
    return const [];
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value == null) return null;
    final s = value is String ? value : value.toString();
    return DateTime.tryParse(s);
  }
}
