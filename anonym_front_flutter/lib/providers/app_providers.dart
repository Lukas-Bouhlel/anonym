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
import '../utils/app_logger.dart';
import '../utils/profile_share_payload.dart';
import '../utils/presence_utils.dart';
import 'app_domain_signals.dart';
import 'auth_providers.dart';
import 'realtime_coordinator.dart';
import 'stores/app_channels_store.dart';
import 'stores/app_commerce_store.dart';
import 'stores/app_presence_store.dart';
import 'stores/app_runtime_store.dart';
import 'stores/app_social_store.dart';

part 'refresh_providers.dart';
part 'social_providers.dart';
part 'channels_providers.dart';
part 'account_providers.dart';
part 'realtime_providers.dart';
part 'realtime_event_handler.dart';
part 'lifecycle_push_providers.dart';
part 'state_reset_providers.dart';
part 'read_only_queries_providers.dart';
part 'domain_services_providers.dart';
part 'refresh_domain_services_providers.dart';
part 'crosscutting_services_providers.dart';
part 'presence_services_providers.dart';

class AppProviderDependencies {
  const AppProviderDependencies({
    required this.accountRepository,
    required this.apiClient,
    required this.friendsRepository,
    required this.channelRepository,
    required this.privateMessageRepository,
    required this.shopRepository,
    required this.inventoryRepository,
    required this.paymentRepository,
    required this.invoiceRepository,
    required this.socketService,
    required this.pushNotificationService,
  });

  final AccountRepository accountRepository;
  final ApiClient apiClient;
  final FriendsRepository friendsRepository;
  final ChannelRepository channelRepository;
  final PrivateMessageRepository privateMessageRepository;
  final ShopRepository shopRepository;
  final InventoryRepository inventoryRepository;
  final PaymentRepository paymentRepository;
  final InvoiceRepository invoiceRepository;
  final SocketService socketService;
  final PushNotificationService pushNotificationService;
}

/// Provider global de l'application.
///
/// Agrège l'état partagé (social, chat, inventaire, notifications, présence),
/// orchestre les repositories et notifie l'UI via [ChangeNotifier].
class AppProvider extends ChangeNotifier with WidgetsBindingObserver {
  AppProvider({
    required AuthProvider authProvider,
    required AppProviderDependencies dependencies,
  }) : _authProvider = authProvider,
       _accountRepository = dependencies.accountRepository,
       _apiClient = dependencies.apiClient,
       _friendsRepository = dependencies.friendsRepository,
       _channelRepository = dependencies.channelRepository,
       _privateMessageRepository = dependencies.privateMessageRepository,
       _shopRepository = dependencies.shopRepository,
       _inventoryRepository = dependencies.inventoryRepository,
       _paymentRepository = dependencies.paymentRepository,
       _invoiceRepository = dependencies.invoiceRepository,
       _socketService = dependencies.socketService,
       _pushNotificationService = dependencies.pushNotificationService {
    _realtimeCoordinator = RealtimeCoordinator(
      apiClient: _apiClient,
      socketService: _socketService,
      isLoggedIn: () => _authProvider.isLoggedIn,
      isAppInForeground: () => _isAppInForeground,
      connectSocketWithLatestAuth: _connectSocketWithLatestAuth,
      scheduleSocialStateRefresh: () => _scheduleSocialStateRefresh(),
      log: _rtLog,
    );
    _realtimeEvents = AppProviderRealtimeEventHandler(this);
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
  final AppDomainSignals _domainSignals = AppDomainSignals();

  int? _activeUserId;
  final _runtimeState = AppRuntimeStore();
  final _socialState = AppSocialStore();
  final _channelsState = AppChannelsStore();
  final _commerceState = AppCommerceStore();
  final _presenceState = AppPresenceStore();
  Timer? _socialRefreshDebounce;
  bool _isRefreshingSocialState = false;
  bool _hasQueuedSocialRefresh = false;
  Timer? _realtimeChannelsRefreshDebounce;
  Timer? _realtimeProfileStatsRefreshDebounce;
  bool _isRefreshingRealtimeChannels = false;
  bool _hasQueuedRealtimeChannelsRefresh = false;
  bool _isRefreshingRealtimeProfileStats = false;
  bool _hasQueuedRealtimeProfileStatsRefresh = false;
  late final RealtimeCoordinator _realtimeCoordinator;
  late final AppProviderRealtimeEventHandler _realtimeEvents;
  late final _SocialDomainService _socialDomainService = _SocialDomainService(
    this,
  );
  late final _ChannelsDomainService _channelsDomainService =
      _ChannelsDomainService(this);
  late final _AccountDomainService _accountDomainService =
      _AccountDomainService(this);
  late final _SocialRefreshDomainService _socialRefreshDomainService =
      _SocialRefreshDomainService(this);
  late final _ChannelsRefreshDomainService _channelsRefreshDomainService =
      _ChannelsRefreshDomainService(this);
  late final _CommerceRefreshDomainService _commerceRefreshDomainService =
      _CommerceRefreshDomainService(this);
  late final _AppProviderParsingService _parsingService =
      _AppProviderParsingService();
  late final _AppProviderMutationService _mutationService =
      _AppProviderMutationService(this);
  late final _AppProviderNotificationService _notificationService =
      _AppProviderNotificationService(this, _parsingService);
  late final _AppProviderPresenceService _presenceService =
      _AppProviderPresenceService(this);

  List<FriendModel> get _friends => _socialState.friends;
  set _friends(List<FriendModel> value) {
    _socialState.friends = value;
    _domainSignals.bumpSocial();
    _domainSignals.bumpPresence();
  }

  List<FriendModel> get _incomingFriendRequests =>
      _socialState.incomingFriendRequests;
  set _incomingFriendRequests(List<FriendModel> value) {
    _socialState.incomingFriendRequests = value;
    _domainSignals.bumpSocial();
    _domainSignals.bumpPresence();
  }

  List<FriendModel> get _outgoingFriendRequests =>
      _socialState.outgoingFriendRequests;
  set _outgoingFriendRequests(List<FriendModel> value) {
    _socialState.outgoingFriendRequests = value;
    _domainSignals.bumpSocial();
    _domainSignals.bumpPresence();
  }

  List<UserModel> get _blockedUsers => _socialState.blockedUsers;
  set _blockedUsers(List<UserModel> value) {
    _socialState.blockedUsers = value;
    _domainSignals.bumpSocial();
    _domainSignals.bumpPresence();
  }

  List<UserModel> get _allUsers => _socialState.allUsers;
  set _allUsers(List<UserModel> value) {
    _socialState.allUsers = value;
    _domainSignals.bumpSocial();
    _domainSignals.bumpPresence();
  }

  List<AppNotificationModel> get _notifications => _socialState.notifications;
  set _notifications(List<AppNotificationModel> value) {
    _socialState.notifications = value;
    _domainSignals.bumpNotifications();
  }

  Set<String> get _readNotificationIds => _socialState.readNotificationIds;
  set _readNotificationIds(Set<String> value) {
    _socialState.readNotificationIds = value;
    _domainSignals.bumpNotifications();
  }

  Map<int, Future<List<ChannelModel>>> get _publicGroupsByUserFuture =>
      _socialState.publicGroupsByUserFuture;
  Map<int, Future<UserModel?>> get _userDetailsHydrationById =>
      _socialState.userDetailsHydrationById;

  Map<int, LiveUserLocationModel> get _liveLocationsByUserId =>
      _presenceState.liveLocationsByUserId;
  Map<int, String> get _presenceByUserId => _presenceState.presenceByUserId;

  String? get _manualPresenceOverride => _runtimeState.manualPresenceOverride;
  set _manualPresenceOverride(String? value) {
    _runtimeState.manualPresenceOverride = value;
  }

  bool get _isAppInForeground => _runtimeState.isAppInForeground;
  set _isAppInForeground(bool value) {
    _runtimeState.isAppInForeground = value;
  }

  List<ChannelModel> get _channels => _channelsState.channels;
  set _channels(List<ChannelModel> value) {
    _channelsState.channels = value;
    _domainSignals.bumpChannels();
  }

  List<ChannelModel> get _publicChannels => _channelsState.publicChannels;
  set _publicChannels(List<ChannelModel> value) {
    _channelsState.publicChannels = value;
    _domainSignals.bumpChannels();
  }

  ChannelModel? get _selectedChannel => _channelsState.selectedChannel;
  set _selectedChannel(ChannelModel? value) {
    _channelsState.selectedChannel = value;
    _domainSignals.bumpChannels();
  }

  List<UserModel> get _channelMembers => _channelsState.channelMembers;
  set _channelMembers(List<UserModel> value) {
    _channelsState.channelMembers = value;
    _domainSignals.bumpChannels();
  }

  List<ChannelMessageModel> get _messages => _channelsState.messages;
  set _messages(List<ChannelMessageModel> value) {
    _channelsState.messages = value;
    _domainSignals.bumpChannels();
  }

  String get _lastPublicChannelsFilter =>
      _channelsState.lastPublicChannelsFilter;
  set _lastPublicChannelsFilter(String value) {
    _channelsState.lastPublicChannelsFilter = value;
    _domainSignals.bumpChannels();
  }

  List<ShopItemModel> get _shopItems => _commerceState.shopItems;
  set _shopItems(List<ShopItemModel> value) {
    _commerceState.shopItems = value;
    _domainSignals.bumpCommerce();
  }

  List<InventoryItemModel> get _inventoryItems => _commerceState.inventoryItems;
  set _inventoryItems(List<InventoryItemModel> value) {
    _commerceState.inventoryItems = value;
    _domainSignals.bumpCommerce();
  }

  List<InvoiceModel> get _invoices => _commerceState.invoices;
  set _invoices(List<InvoiceModel> value) {
    _commerceState.invoices = value;
    _domainSignals.bumpCommerce();
  }

  bool get _isBootstrapping => _runtimeState.isBootstrapping;
  set _isBootstrapping(bool value) {
    if (_runtimeState.isBootstrapping == value) return;
    _runtimeState.isBootstrapping = value;
    _domainSignals.bumpOrchestrator();
  }

  bool get _isLoadingMessages => _runtimeState.isLoadingMessages;
  set _isLoadingMessages(bool value) {
    if (_runtimeState.isLoadingMessages == value) return;
    _runtimeState.isLoadingMessages = value;
    _domainSignals.bumpChannels();
  }

  bool get _isSubmitting => _runtimeState.isSubmitting;
  set _isSubmitting(bool value) {
    if (_runtimeState.isSubmitting == value) return;
    _runtimeState.isSubmitting = value;
    _domainSignals.bumpOrchestrator();
    _domainSignals.bumpSocial();
    _domainSignals.bumpCommerce();
  }

  String? get _errorMessage => _runtimeState.errorMessage;
  set _errorMessage(String? value) {
    if (_runtimeState.errorMessage == value) return;
    _runtimeState.errorMessage = value;
    _domainSignals.bumpOrchestrator();
    _domainSignals.bumpSocial();
    _domainSignals.bumpChannels();
    _domainSignals.bumpCommerce();
  }

  String? get _messageError => _runtimeState.messageError;
  set _messageError(String? value) {
    if (_runtimeState.messageError == value) return;
    _runtimeState.messageError = value;
    _domainSignals.bumpChannels();
  }

  int get _realtimeStatsVersion => _runtimeState.realtimeStatsVersion;
  set _realtimeStatsVersion(int value) {
    if (_runtimeState.realtimeStatsVersion == value) return;
    _runtimeState.realtimeStatsVersion = value;
    _domainSignals.bumpPresence();
  }

  void _rtLog(String message) {
    AppLogger.debug(message, scope: 'FRIENDS-RT');
  }

  void _notifyStateChanged() {
    notifyListeners();
  }

  void _markPresenceStateChanged() {
    _domainSignals.bumpPresence();
  }

  Listenable get orchestratorListenable => _domainSignals.orchestrator;
  Listenable get socialListenable => _domainSignals.social;
  Listenable get channelsListenable => _domainSignals.channels;
  Listenable get commerceListenable => _domainSignals.commerce;
  Listenable get presenceListenable => _domainSignals.presence;
  Listenable get notificationsListenable => _domainSignals.notifications;

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
    _domainSignals.dispose();
    super.dispose();
  }
}
