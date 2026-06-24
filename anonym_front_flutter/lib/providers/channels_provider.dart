import 'package:flutter/foundation.dart';

import '../models/channel_message_model.dart';
import '../models/channel_model.dart';
import '../models/friend_model.dart';
import '../models/user_model.dart';
import 'app_providers.dart';

/// Domain provider for channels and direct messages.
class ChannelsProvider extends ChangeNotifier {
  ChannelsProvider(this._app) {
    _listener = notifyListeners;
    _app.channelsListenable.addListener(_listener);
  }

  final AppProvider _app;
  late final VoidCallback _listener;

  List<ChannelModel> get channels => _app.channels;
  List<ChannelModel> get publicChannels => _app.publicChannels;
  ChannelModel? get selectedChannel => _app.selectedChannel;
  List<UserModel> get channelMembers => _app.channelMembers;
  List<ChannelMessageModel> get messages => _app.messages;
  List<FriendModel> get availableFriendsForSelectedChannel =>
      _app.availableFriendsForSelectedChannel;

  bool get isLoadingMessages => _app.isLoadingMessages;
  String? get errorMessage => _app.errorMessage;
  String? get messageError => _app.messageError;

  UserModel? userById(int userId) => _app.userById(userId);

  Future<UserModel?> hydrateUserDetails(
    int userId, {
    bool forceRefresh = false,
  }) {
    return _app.hydrateUserDetails(userId, forceRefresh: forceRefresh);
  }

  Future<void> refreshChannels({bool silent = false}) {
    return _app.refreshChannels(silent: silent);
  }

  Future<void> refreshPublicChannels({
    String filter = 'all',
    bool silent = false,
  }) {
    return _app.refreshPublicChannels(filter: filter, silent: silent);
  }

  Future<List<ChannelModel>> loadJoinDirectoryChannels({
    String filter = 'all',
  }) {
    return _app.loadJoinDirectoryChannels(filter: filter);
  }

  Future<void> selectChannel(ChannelModel channel) =>
      _app.selectChannel(channel);

  Future<void> sendMessage(String content) => _app.sendMessage(content);

  Future<void> sendMessageWithImage({
    required String? imagePath,
    List<int>? imageBytes,
    String? imageFileName,
    String content = '',
  }) {
    return _app.sendMessageWithImage(
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
    return _app.updateMessage(messageId: messageId, content: content);
  }

  Future<void> deleteMessage(int messageId) => _app.deleteMessage(messageId);

  Future<void> inviteUsersToSelectedChannel(List<int> userIds) {
    return _app.inviteUsersToSelectedChannel(userIds);
  }

  Future<void> removeMemberFromSelectedChannel(int userId) {
    return _app.removeMemberFromSelectedChannel(userId);
  }

  Future<void> leaveSelectedChannel() => _app.leaveSelectedChannel();

  Future<void> deleteSelectedChannel() => _app.deleteSelectedChannel();

  Future<void> createChannel({
    required String name,
    required String description,
    String channelType = 'GROUP',
    String visibility = 'PUBLIC',
    List<int>? memberIds,
    String? imageFilePath,
  }) {
    return _app.createChannel(
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
    return _app.createGroupChannel(
      name: name,
      description: description,
      visibility: visibility,
      imageFilePath: imageFilePath,
    );
  }

  Future<void> createPrivateDm({required int targetUserId}) {
    return _app.createPrivateDm(targetUserId: targetUserId);
  }

  Future<void> joinPublicChannel(int channelId, {String publicFilter = 'all'}) {
    return _app.joinPublicChannel(channelId, publicFilter: publicFilter);
  }

  Future<void> joinByInviteCode(String code) => _app.joinByInviteCode(code);

  Future<Map<String, dynamic>?> createInviteLinkForSelectedChannel({
    required String mode,
    int? expiresInMinutes,
  }) {
    return _app.createInviteLinkForSelectedChannel(
      mode: mode,
      expiresInMinutes: expiresInMinutes,
    );
  }

  Future<void> updateSelectedChannelCover(String imageFilePath) {
    return _app.updateSelectedChannelCover(imageFilePath);
  }

  Future<void> updateSelectedGroup({
    String? name,
    String? description,
    String? visibility,
    String? imageFilePath,
  }) {
    return _app.updateSelectedGroup(
      name: name,
      description: description,
      visibility: visibility,
      imageFilePath: imageFilePath,
    );
  }

  Future<bool> openChannelById(int channelId) =>
      _app.openChannelById(channelId);

  void closeSelectedChannelView() => _app.closeSelectedChannelView();

  void clearMessageError() => _app.clearMessageError();

  @override
  void dispose() {
    _app.channelsListenable.removeListener(_listener);
    super.dispose();
  }
}
