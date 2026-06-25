import '../../models/app_notification_model.dart';
import '../../models/channel_model.dart';
import '../../models/friend_model.dart';
import '../../models/user_model.dart';

class AppSocialStore {
  List<FriendModel> friends = const [];
  List<FriendModel> incomingFriendRequests = const [];
  List<FriendModel> outgoingFriendRequests = const [];
  List<UserModel> blockedUsers = const [];
  List<UserModel> allUsers = const [];
  List<AppNotificationModel> notifications = const [];
  Set<String> readNotificationIds = <String>{};
  final Map<int, Future<List<ChannelModel>>> publicGroupsByUserFuture = {};
  final Map<int, Future<UserModel?>> userDetailsHydrationById = {};
}
