import 'package:flutter/foundation.dart';

import '../models/channel_model.dart';
import '../models/friend_model.dart';
import '../models/user_model.dart';
import 'app_providers.dart';

/// Vue domaine social (amis, demandes, utilisateurs) adossée au provider app.
///
/// Cette classe isole l'accès UI aux fonctionnalités sociales tout en
/// réutilisant l'orchestrateur applicatif existant.
class SocialProvider extends ChangeNotifier {
  SocialProvider(this._app) {
    _listener = notifyListeners;
    _app.socialListenable.addListener(_listener);
  }

  final AppProvider _app;
  late final VoidCallback _listener;

  List<FriendModel> get friends => _app.friends;
  List<FriendModel> get incomingFriendRequests => _app.incomingFriendRequests;
  List<FriendModel> get outgoingFriendRequests => _app.outgoingFriendRequests;
  List<UserModel> get blockedUsers => _app.blockedUsers;
  List<UserModel> get allUsers => _app.allUsers;
  List<UserModel> get discoverableUsers => _app.discoverableUsers;
  String? get errorMessage => _app.errorMessage;
  bool get isSubmitting => _app.isSubmitting;

  UserModel? userById(int userId) => _app.userById(userId);

  bool isFriendRequestPending({int? userId, String? username}) {
    return _app.isFriendRequestPending(userId: userId, username: username);
  }

  Future<void> refreshFriends({bool silent = false}) {
    return _app.refreshFriends(silent: silent);
  }

  Future<void> refreshFriendRequests({bool silent = false}) {
    return _app.refreshFriendRequests(silent: silent);
  }

  Future<void> refreshBlockedUsers({bool silent = false}) {
    return _app.refreshBlockedUsers(silent: silent);
  }

  Future<void> refreshUsers({bool silent = false}) {
    return _app.refreshUsers(silent: silent);
  }

  Future<UserModel?> hydrateUserDetails(
    int userId, {
    bool forceRefresh = false,
  }) {
    return _app.hydrateUserDetails(userId, forceRefresh: forceRefresh);
  }

  Future<FriendModel?> addFriendByUsername(String username, {int? userId}) {
    return _app.addFriendByUsername(username, userId: userId);
  }

  Future<void> respondToIncomingFriendRequest({
    required int requestId,
    required String status,
  }) {
    return _app.respondToIncomingFriendRequest(
      requestId: requestId,
      status: status,
    );
  }

  Future<void> cancelOutgoingFriendRequest(int requestId) {
    return _app.cancelOutgoingFriendRequest(requestId);
  }

  Future<void> unblockUser(int userId) {
    return _app.unblockUser(userId);
  }

  Future<void> blockUser(int userId) {
    return _app.blockUser(userId);
  }

  Future<void> deleteFriend(int friendId) {
    return _app.deleteFriend(friendId);
  }

  Future<List<ChannelModel>> publicGroupsForUser(
    int userId, {
    bool forceRefresh = false,
  }) {
    return _app.publicGroupsForUser(userId, forceRefresh: forceRefresh);
  }

  Future<int> shareProfileToUsers({
    required int profileUserId,
    required String profileUsername,
    required List<int> targetUserIds,
    String? profileAvatarUrl,
    String? profileFrameUrl,
  }) {
    return _app.shareProfileToUsers(
      profileUserId: profileUserId,
      profileUsername: profileUsername,
      targetUserIds: targetUserIds,
      profileAvatarUrl: profileAvatarUrl,
      profileFrameUrl: profileFrameUrl,
    );
  }

  @override
  void dispose() {
    _app.socialListenable.removeListener(_listener);
    super.dispose();
  }
}
