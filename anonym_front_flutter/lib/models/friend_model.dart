import 'user_model.dart';

/// Modèle représentant une relation d'amitié (active, pending, etc.).
class FriendModel {
  const FriendModel({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.status,
    this.friendDetails,
  });

  final int id;
  final int userId;
  final int friendId;
  final String status;
  final UserModel? friendDetails;

  /// Construit une relation d'amitié depuis une payload JSON.
  factory FriendModel.fromJson(Map<String, dynamic> json) {
    final detailsJson =
        json['FriendDetails'] ??
        json['friendDetails'] ??
        json['User'] ??
        json['UserDetails'] ??
        json['userDetails'] ??
        json['user'] ??
        json['friend'] ??
        json['sender'] ??
        json['receiver'];

    return FriendModel(
      id: _toInt(json['id']),
      userId: _toInt(json['user_id'] ?? json['userId']),
      friendId: _toInt(json['friend_id'] ?? json['friendId']),
      status: (json['status'] ?? 'ACTIVE').toString(),
      friendDetails: detailsJson is Map<String, dynamic>
          ? UserModel.fromJson(detailsJson)
          : null,
    );
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
