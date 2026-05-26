import 'dart:convert';

/// Payload de partage d'invitation vers un groupe/canal.
class GroupInvitePayload {
  const GroupInvitePayload({
    required this.channelId,
    required this.channelName,
    required this.channelDescription,
    required this.channelVisibility,
    required this.inviteCode,
    required this.invitedByUserId,
    required this.invitedByUsername,
    this.channelCoverImage,
  });

  final int channelId;
  final String channelName;
  final String channelDescription;
  final String channelVisibility;
  final String inviteCode;
  final int invitedByUserId;
  final String invitedByUsername;
  final String? channelCoverImage;
}

/// Encodage/décodage du payload d'invitation dans un message texte.
abstract final class GroupInvitePayloadCodec {
  static const String _prefix = 'ANONYM_GROUP_INVITE:';

  /// Tente de décoder un contenu texte en [GroupInvitePayload].
  static GroupInvitePayload? tryDecode(String rawContent) {
    final normalized = rawContent.trim();
    if (!normalized.startsWith(_prefix)) return null;
    final jsonPart = normalized.substring(_prefix.length).trim();
    if (jsonPart.isEmpty) return null;
    try {
      final decoded = jsonDecode(jsonPart);
      if (decoded is! Map<String, dynamic>) return null;
      final channelId = _toInt(decoded['channelId']);
      final channelName = (decoded['channelName'] ?? '').toString().trim();
      final channelDescription = (decoded['channelDescription'] ?? '')
          .toString()
          .trim();
      final channelVisibility = (decoded['channelVisibility'] ?? 'PRIVATE')
          .toString()
          .trim()
          .toUpperCase();
      final inviteCode = (decoded['inviteCode'] ?? '').toString().trim();
      final invitedByUserId = _toInt(decoded['invitedByUserId']);
      final invitedByUsername = (decoded['invitedByUsername'] ?? '')
          .toString()
          .trim();
      final channelCoverImage = (decoded['channelCoverImage'] ?? '')
          .toString()
          .trim();
      if (channelId <= 0 || channelName.isEmpty) return null;
      return GroupInvitePayload(
        channelId: channelId,
        channelName: channelName,
        channelDescription: channelDescription,
        channelVisibility: channelVisibility,
        inviteCode: inviteCode,
        invitedByUserId: invitedByUserId,
        invitedByUsername: invitedByUsername,
        channelCoverImage: channelCoverImage.isEmpty ? null : channelCoverImage,
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
