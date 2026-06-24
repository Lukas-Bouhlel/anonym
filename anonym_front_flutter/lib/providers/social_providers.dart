part of 'app_providers.dart';

/// Operations sociales: amis, blocages, partages de profil.
extension AppProviderSocialX on AppProvider {
  Future<FriendModel?> addFriendByUsername(String username, {int? userId}) {
    return _socialDomainService.addFriendByUsername(username, userId: userId);
  }

  Future<void> respondToIncomingFriendRequest({
    required int requestId,
    required String status,
  }) {
    return _socialDomainService.respondToIncomingFriendRequest(
      requestId: requestId,
      status: status,
    );
  }

  Future<void> cancelOutgoingFriendRequest(int requestId) {
    return _socialDomainService.cancelOutgoingFriendRequest(requestId);
  }

  Future<void> unblockUser(int userId) {
    return _socialDomainService.unblockUser(userId);
  }

  Future<void> blockUser(int userId) {
    return _socialDomainService.blockUser(userId);
  }

  Future<void> deleteFriend(int friendId) {
    return _socialDomainService.deleteFriend(friendId);
  }

  Future<void> createChannel({
    required String name,
    required String description,
    String channelType = 'GROUP',
    String visibility = 'PUBLIC',
    List<int>? memberIds,
    String? imageFilePath,
  }) {
    return _socialDomainService.createChannel(
      name: name,
      description: description,
      channelType: channelType,
      visibility: visibility,
      memberIds: memberIds,
      imageFilePath: imageFilePath,
    );
  }

  Future<void> createGroupChannel({
    required String name,
    String description = '',
    required String visibility,
    String? imageFilePath,
  }) {
    return _socialDomainService.createGroupChannel(
      name: name,
      description: description,
      visibility: visibility,
      imageFilePath: imageFilePath,
    );
  }

  Future<void> createPrivateDm({required int targetUserId}) {
    return _socialDomainService.createPrivateDm(targetUserId: targetUserId);
  }

  Future<int> shareProfileToUsers({
    required int profileUserId,
    required String profileUsername,
    required List<int> targetUserIds,
    String? profileAvatarUrl,
    String? profileFrameUrl,
  }) {
    return _socialDomainService.shareProfileToUsers(
      profileUserId: profileUserId,
      profileUsername: profileUsername,
      targetUserIds: targetUserIds,
      profileAvatarUrl: profileAvatarUrl,
      profileFrameUrl: profileFrameUrl,
    );
  }
}
