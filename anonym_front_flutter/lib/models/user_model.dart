import 'inventory_item_model.dart';
import '../utils/media_url.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.avatar,
    this.bio,
    this.roles,
    this.inventories = const [],
  });

  final int id;
  final String username;
  final String email;
  final String? avatar;
  final String? bio;
  final String? roles;
  final List<InventoryItemModel> inventories;

  bool get isAdmin => roles == 'ADMIN' || roles == 'SUPER_ADMIN';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _toInt(json['id'] ?? json['user_id'] ?? json['userId']),
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      avatar: MediaUrl.nullable(json['avatar']?.toString()),
      bio: json['bio']?.toString(),
      roles: json['roles']?.toString(),
      inventories: _parseInventories(json),
    );
  }

  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? avatar,
    String? bio,
    String? roles,
    List<InventoryItemModel>? inventories,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      roles: roles ?? this.roles,
      inventories: inventories ?? this.inventories,
    );
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
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
}
