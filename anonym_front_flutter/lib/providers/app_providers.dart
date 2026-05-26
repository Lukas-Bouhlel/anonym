import 'dart:math';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification_model.dart';
import '../models/channel_message_model.dart';
import '../models/channel_model.dart';
import '../models/friend_model.dart';
import '../models/inventory_item_model.dart';
import '../models/invoice_model.dart';
import '../models/live_user_location_model.dart';
import '../models/payment_confirmation_model.dart';
import '../models/shop_item_model.dart';
import '../models/user_model.dart';
import '../services/account_repository.dart';
import '../services/api_client.dart';
import '../services/channel_repository.dart';
import '../services/friends_repository.dart';
import '../services/inventory_repository.dart';
import '../services/invoice_repository.dart';
import '../services/payment_repository.dart';
import '../services/private_message_repository.dart';
import '../services/push_notification_service.dart';
import '../services/shop_repository.dart';
import '../services/socket_service.dart';
import '../utils/api_error_parser.dart';
import '../utils/profile_share_payload.dart';
import '../utils/presence_utils.dart';
import 'auth_providers.dart';


part 'refresh_providers.dart';
part 'social_providers.dart';
part 'channels_providers.dart';
part 'account_providers.dart';
part 'realtime_providers.dart';
part 'lifecycle_push_providers.dart';
part 'state_reset_providers.dart';

/// Provider global de l'application.
///
/// Agrège l'état partagé (social, chat, inventaire, notifications, présence),
/// orchestre les repositories et notifie l'UI via [ChangeNotifier].
class AppProvider extends ChangeNotifier with WidgetsBindingObserver {
  AppProvider({
    required AuthProvider authProvider,
    required AccountRepository accountRepository,
    required ApiClient apiClient,
    required FriendsRepository friendsRepository,
    required ChannelRepository channelRepository,
    required PrivateMessageRepository privateMessageRepository,
    required ShopRepository shopRepository,
    required InventoryRepository inventoryRepository,
    required PaymentRepository paymentRepository,
    required InvoiceRepository invoiceRepository,
    required SocketService socketService,
    required PushNotificationService pushNotificationService,
  }) : _authProvider = authProvider,
       _accountRepository = accountRepository,
       _apiClient = apiClient,
       _friendsRepository = friendsRepository,
       _channelRepository = channelRepository,
       _privateMessageRepository = privateMessageRepository,
       _shopRepository = shopRepository,
       _inventoryRepository = inventoryRepository,
       _paymentRepository = paymentRepository,
       _invoiceRepository = invoiceRepository,
       _socketService = socketService,
       _pushNotificationService = pushNotificationService {
    WidgetsBinding.instance.addObserver(this);
    _authListener = _handleAuthChange;
    _authProvider.addListener(_authListener);
    _handleAuthChange();
  }

  final AuthProvider _authProvider;
  final AccountRepository _accountRepository;
  final ApiClient _apiClient;
  final FriendsRepository _friendsRepository;
  final ChannelRepository _channelRepository;
  final PrivateMessageRepository _privateMessageRepository;
  final ShopRepository _shopRepository;
  final InventoryRepository _inventoryRepository;
  final PaymentRepository _paymentRepository;
  final InvoiceRepository _invoiceRepository;
  final SocketService _socketService;
  final PushNotificationService _pushNotificationService;
  StreamSubscription<String>? _pushTokenRefreshSubscription;
  StreamSubscription<dynamic>? _pushOpenedAppSubscription;
  StreamSubscription<dynamic>? _pushForegroundMessageSubscription;
  String? _lastRegisteredPushToken;

  late final VoidCallback _authListener;

  int? _activeUserId;
  bool _isBootstrapping = false;
  bool _isLoadingMessages = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _messageError;

  List<FriendModel> _friends = const [];
  List<FriendModel> _incomingFriendRequests = const [];
  List<FriendModel> _outgoingFriendRequests = const [];
  List<UserModel> _blockedUsers = const [];
  List<ChannelModel> _channels = const [];
  List<ChannelModel> _publicChannels = const [];
  ChannelModel? _selectedChannel;
  List<UserModel> _channelMembers = const [];
  List<ChannelMessageModel> _messages = const [];
  List<AppNotificationModel> _notifications = const [];
  Set<String> _readNotificationIds = <String>{};
  List<ShopItemModel> _shopItems = const [];
  List<InventoryItemModel> _inventoryItems = const [];
  List<InvoiceModel> _invoices = const [];
  List<UserModel> _allUsers = const [];
  final Map<int, LiveUserLocationModel> _liveLocationsByUserId = {};
  final Map<int, String> _presenceByUserId = {};
  final Map<int, Future<List<ChannelModel>>> _publicGroupsByUserFuture = {};
  final Map<int, Future<UserModel?>> _userDetailsHydrationById = {};
  String? _manualPresenceOverride;
  bool _isAppInForeground = true;
  Timer? _socialRefreshDebounce;
  bool _isRefreshingSocialState = false;
  bool _hasQueuedSocialRefresh = false;
  Timer? _realtimeChannelsRefreshDebounce;
  Timer? _realtimeProfileStatsRefreshDebounce;
  bool _isRefreshingRealtimeChannels = false;
  bool _hasQueuedRealtimeChannelsRefresh = false;
  bool _isRefreshingRealtimeProfileStats = false;
  bool _hasQueuedRealtimeProfileStatsRefresh = false;
  int _realtimeStatsVersion = 0;
  String _lastPublicChannelsFilter = 'all';
  Timer? _sessionKeepAliveTimer;
  bool _isRecoveringSocketSession = false;
  DateTime? _lastSocketRecoveryAt;

  void _rtLog(String message) {
    // ignore: avoid_print
    print('[FRIENDS-RT-FLUTTER] $message');
  }

  void _notifyStateChanged() {
    notifyListeners();
  }

  bool get isBootstrapping => _isBootstrapping;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isSubmitting => _isSubmitting;
  bool get isSocketConnected => _socketService.isConnected;
  String? get errorMessage => _errorMessage;
  String? get messageError => _messageError;

  List<FriendModel> get friends => _friends;
  List<FriendModel> get incomingFriendRequests => _incomingFriendRequests;
  List<FriendModel> get outgoingFriendRequests => _outgoingFriendRequests;
  List<UserModel> get blockedUsers => _blockedUsers;
  List<ChannelModel> get channels => _channels;
  List<ChannelModel> get publicChannels => _publicChannels;
  ChannelModel? get selectedChannel => _selectedChannel;
  List<UserModel> get channelMembers => _channelMembers;
  List<ChannelMessageModel> get messages => _messages;
  List<AppNotificationModel> get notifications => _notifications;
  int get unreadNotificationsCount =>
      _notifications.where((item) => !item.isRead).length;
  List<ShopItemModel> get shopItems => _shopItems;
  List<InventoryItemModel> get inventoryItems => _inventoryItems;
  List<InvoiceModel> get invoices => _invoices;
  List<UserModel> get allUsers => _allUsers;
  List<LiveUserLocationModel> get liveUserLocations {
    final allowedIds = _visibleLocationUserIds;
    if (allowedIds.isEmpty) return const [];
    return _liveLocationsByUserId.values
        .where((location) => allowedIds.contains(location.userId))
        .toList(growable: false);
  }

  int get realtimeStatsVersion => _realtimeStatsVersion;

  UserModel? userById(int userId) {
    if (userId <= 0) return null;
    for (final user in _allUsers) {
      if (user.id == userId) return user;
    }
    return null;
  }

  String? activeFrameUrlForUser(int userId) {
    return _resolveSharedProfileFrameUrl(userId);
  }

  String presenceStatusForUser(int userId, {bool isCurrentUser = false}) {
    return PresenceUtils.effectiveForViewer(
      _presenceByUserId[userId],
      isCurrentUser: isCurrentUser,
    );
  }

  String presenceLabelForUser(int userId, {bool isCurrentUser = false}) {
    return PresenceUtils.label(
      _presenceByUserId[userId],
      isCurrentUser: isCurrentUser,
    );
  }

  bool isFriendRequestPending({int? userId, String? username}) {
    if (userId != null &&
        _outgoingFriendRequests.any((request) => request.friendId == userId)) {
      return true;
    }
    final normalized = username?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return false;
    return _outgoingFriendRequests.any((request) {
      final requestName = request.friendDetails?.username.trim().toLowerCase();
      return requestName == normalized;
    });
  }

  List<UserModel> get discoverableUsers {
    final me = _authProvider.user?.id;
    final friendIds = _friends
        .where((friend) => _isActiveFriendStatus(friend.status))
        .map((friend) => friend.friendId)
        .toSet();
    final outgoingIds = _outgoingFriendRequests
        .map((request) => request.friendId)
        .toSet();
    final incomingIds = _incomingFriendRequests
        .map((request) => request.userId)
        .toSet();
    final blockedIds = _blockedUsers.map((user) => user.id).toSet();

    return _allUsers
        .where((user) {
          if (user.id == me) return false;
          if (friendIds.contains(user.id)) return false;
          if (outgoingIds.contains(user.id)) return false;
          if (incomingIds.contains(user.id)) return false;
          if (blockedIds.contains(user.id)) return false;
          return true;
        })
        .toList(growable: false);
  }

  List<FriendModel> get availableFriendsForSelectedChannel {
    final selected = _selectedChannel;
    if (selected == null) return const [];
    final memberIds = _channelMembers.map((member) => member.id).toSet();
    return _friends
        .where(
          (friend) =>
              friend.status.trim().toUpperCase() == 'ACTIVE' &&
              !memberIds.contains(friend.friendId) &&
              friend.friendDetails != null,
        )
        .toList(growable: false);
  }

  bool isArticleOwned(int articleId) {
    return _inventoryItems.any((item) => item.articleId == articleId);
  }

  InventoryItemModel? inventoryByArticleId(int articleId) {
    try {
      return _inventoryItems.firstWhere((item) => item.articleId == articleId);
    } catch (_) {
      return null;
    }
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppInForeground = state == AppLifecycleState.resumed;
    if (!_authProvider.isLoggedIn) return;
    if (_activeUserId == null) return;
    _applyLifecyclePresence(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authProvider.removeListener(_authListener);
    _socialRefreshDebounce?.cancel();
    _realtimeChannelsRefreshDebounce?.cancel();
    _realtimeProfileStatsRefreshDebounce?.cancel();
    _stopSessionKeepAlive();
    _socketService.disconnect();
    _pushTokenRefreshSubscription?.cancel();
    _pushOpenedAppSubscription?.cancel();
    _pushForegroundMessageSubscription?.cancel();
    super.dispose();
  }
}
