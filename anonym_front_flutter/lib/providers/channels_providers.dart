part of 'app_providers.dart';

/// Operations liees aux conversations, messages et groupes.
extension AppProviderChannelsX on AppProvider {
  Future<void> selectChannel(ChannelModel channel) {
    return _channelsDomainService.selectChannel(channel);
  }

  Future<void> sendMessage(String content) {
    return _channelsDomainService.sendMessage(content);
  }

  Future<void> sendMessageWithImage({
    required String? imagePath,
    List<int>? imageBytes,
    String? imageFileName,
    String content = '',
  }) {
    return _channelsDomainService.sendMessageWithImage(
      imagePath: imagePath,
      imageBytes: imageBytes,
      imageFileName: imageFileName,
      content: content,
    );
  }

  Future<void> updateMessage({
    required int messageId,
    required String content,
  }) {
    return _channelsDomainService.updateMessage(
      messageId: messageId,
      content: content,
    );
  }

  Future<void> deleteMessage(int messageId) {
    return _channelsDomainService.deleteMessage(messageId);
  }

  Future<void> inviteUsersToSelectedChannel(List<int> userIds) {
    return _channelsDomainService.inviteUsersToSelectedChannel(userIds);
  }

  Future<void> removeMemberFromSelectedChannel(int userId) {
    return _channelsDomainService.removeMemberFromSelectedChannel(userId);
  }

  Future<void> leaveSelectedChannel() {
    return _channelsDomainService.leaveSelectedChannel();
  }

  Future<void> deleteSelectedChannel() {
    return _channelsDomainService.deleteSelectedChannel();
  }

  Future<void> joinPublicChannel(int channelId, {String publicFilter = 'all'}) {
    return _channelsDomainService.joinPublicChannel(
      channelId,
      publicFilter: publicFilter,
    );
  }

  Future<void> joinByInviteCode(String code) {
    return _channelsDomainService.joinByInviteCode(code);
  }

  Future<Map<String, dynamic>?> createInviteLinkForSelectedChannel({
    required String mode,
    int? expiresInMinutes,
  }) {
    return _channelsDomainService.createInviteLinkForSelectedChannel(
      mode: mode,
      expiresInMinutes: expiresInMinutes,
    );
  }

  Future<void> updateSelectedChannelCover(String imageFilePath) {
    return _channelsDomainService.updateSelectedChannelCover(imageFilePath);
  }

  Future<void> updateSelectedGroup({
    String? name,
    String? description,
    String? visibility,
    String? imageFilePath,
  }) {
    return _channelsDomainService.updateSelectedGroup(
      name: name,
      description: description,
      visibility: visibility,
      imageFilePath: imageFilePath,
    );
  }

  void closeSelectedChannelView() {
    _channelsDomainService.closeSelectedChannelView();
  }
}
