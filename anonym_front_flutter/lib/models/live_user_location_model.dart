class LiveUserLocationModel {
  const LiveUserLocationModel({
    required this.userId,
    required this.username,
    required this.latitude,
    required this.longitude,
    this.avatar,
    this.updatedAt,
  });

  final int userId;
  final String username;
  final String? avatar;
  final double latitude;
  final double longitude;
  final DateTime? updatedAt;

  LiveUserLocationModel copyWith({
    int? userId,
    String? username,
    String? avatar,
    double? latitude,
    double? longitude,
    DateTime? updatedAt,
  }) {
    return LiveUserLocationModel(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory LiveUserLocationModel.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    final nestedUser = rawUser is Map
        ? Map<String, dynamic>.from(rawUser)
        : null;

    final userId = _toInt(
      json['userId'] ??
          json['user_id'] ??
          json['id'] ??
          nestedUser?['id'] ??
          nestedUser?['userId'] ??
          nestedUser?['user_id'],
    );

    final username =
        (json['username'] ??
                json['pseudo'] ??
                nestedUser?['username'] ??
                nestedUser?['pseudo'] ??
                '')
            .toString()
            .trim();

    final avatarValue =
        json['avatar'] ?? nestedUser?['avatar'] ?? nestedUser?['image'];
    final avatar = avatarValue?.toString().trim();

    final lat = _toDouble(
      json['lat'] ?? json['latitude'] ?? json['y'] ?? json['position']?['lat'],
    );
    final lng = _toDouble(
      json['lng'] ??
          json['lon'] ??
          json['longitude'] ??
          json['x'] ??
          json['position']?['lng'] ??
          json['position']?['lon'],
    );

    final updatedAt = _toDateTime(
      json['updatedAt'] ?? json['updated_at'] ?? json['timestamp'],
    );

    return LiveUserLocationModel(
      userId: userId,
      username: username.isEmpty ? 'Utilisateur' : username,
      avatar: (avatar == null || avatar.isEmpty) ? null : avatar,
      latitude: lat,
      longitude: lng,
      updatedAt: updatedAt,
    );
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _toDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _toDateTime(Object? value) {
    if (value is DateTime) return value;
    if (value is int) {
      if (value <= 0) return null;
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is num) {
      final ms = value.toInt();
      if (ms <= 0) return null;
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
