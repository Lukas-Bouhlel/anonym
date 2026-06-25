import 'dart:convert';

/// Payload minimal de partage de profil utilisateur.
class ProfileSharePayload {
  const ProfileSharePayload({
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.frameUrl,
  });

  final int userId;
  final String username;
  final String? avatarUrl;
  final String? frameUrl;
}

/// Encodage/décodage d'un [ProfileSharePayload] dans un message texte.
abstract final class ProfileSharePayloadCodec {
  static const String _prefix = 'ANONYM_PROFILE_SHARE:';

  /// Encode un payload en chaîne sérialisée partageable.
  static String encode(ProfileSharePayload payload) {
    final safeUsername = payload.username.trim();
    final safeAvatarUrl = payload.avatarUrl?.trim();
    final safeFrameUrl = payload.frameUrl?.trim();
    final body = jsonEncode({
      'userId': payload.userId,
      'username': safeUsername,
      if (safeAvatarUrl != null && safeAvatarUrl.isNotEmpty)
        'avatarUrl': safeAvatarUrl,
      if (safeFrameUrl != null && safeFrameUrl.isNotEmpty)
        'frameUrl': safeFrameUrl,
    });
    return '$_prefix$body';
  }

  /// Tente de décoder une chaîne en payload de partage de profil.
  static ProfileSharePayload? tryDecode(String rawContent) {
    final normalized = rawContent.trim();
    if (!normalized.startsWith(_prefix)) return null;
    final jsonPart = normalized.substring(_prefix.length).trim();
    if (jsonPart.isEmpty) return null;
    try {
      final decoded = jsonDecode(jsonPart);
      if (decoded is! Map<String, dynamic>) return null;
      final userId = _toInt(decoded['userId']);
      final username = (decoded['username'] ?? '').toString().trim();
      final avatarUrl = (decoded['avatarUrl'] ?? '').toString().trim();
      final frameUrl = (decoded['frameUrl'] ?? '').toString().trim();
      if (userId <= 0 || username.isEmpty) return null;
      return ProfileSharePayload(
        userId: userId,
        username: username,
        avatarUrl: avatarUrl.isEmpty ? null : avatarUrl,
        frameUrl: frameUrl.isEmpty ? null : frameUrl,
      );
    } catch (_) {
      return null;
    }
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
