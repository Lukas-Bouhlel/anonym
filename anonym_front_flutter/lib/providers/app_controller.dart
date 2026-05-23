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
import '../utils/presence_utils.dart';
import 'auth_controller.dart';

class AppController extends ChangeNotifier with WidgetsBindingObserver {
  AppController({
    required AuthController authController,
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
  }) : _authController = authController,
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
    _authController.addListener(_authListener);
    _handleAuthChange();
  }

  final AuthController _authController;
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
  String? _manualPresenceOverride;

  bool get isBootstrapping => _isBootstrapping;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isSubmitting => _isSubmitting;
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
  List<LiveUserLocationModel> get liveUserLocations =>
      _liveLocationsByUserId.values.toList(growable: false);

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
    final me = _authController.user?.id;
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

  Future<void> refreshAll() async {
    if (!_authController.isLoggedIn) return;
    _isBootstrapping = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _loadReadNotificationIds();
      await Future.wait([
        _refreshCurrentUser(),
        refreshFriends(silent: true),
        refreshFriendRequests(silent: true),
        refreshBlockedUsers(silent: true),
        refreshUsers(silent: true),
        refreshChannels(silent: true),
        refreshPublicChannels(silent: true),
        refreshShop(silent: true),
        refreshInventory(silent: true),
        refreshInvoices(silent: true),
      ]);
      _rebuildPendingFriendRequestNotifications();
      _rebuildChannelUnreadNotifications();
    } catch (e) {
      _errorMessage = ApiErrorParser.parse(
        e,
        fallback: 'Chargement impossible',
      );
    } finally {
      _isBootstrapping = false;
      notifyListeners();
    }
  }

  Future<void> refreshFriends({bool silent = false}) async {
    await _wrap(
      () async {
        _friends = await _friendsRepository.readAll();
        for (final friend in _friends) {
          final details = friend.friendDetails;
          if (details == null || details.id <= 0) continue;
          _presenceByUserId[details.id] = PresenceUtils.normalize(
            details.presenceStatus,
          );
        }
      },
      silent: silent,
      fallbackMessage: 'Impossible de charger les amis',
    );
  }

  Future<void> refreshFriendRequests({bool silent = false}) async {
    await _wrap(
      () async {
        final responses = await Future.wait([
          _friendsRepository.readIncomingRequests(),
          _friendsRepository.readOutgoingRequests(),
        ]);
        _incomingFriendRequests = responses[0];
        _outgoingFriendRequests = responses[1];
        for (final request in _incomingFriendRequests) {
          final details = request.friendDetails;
          if (details == null || details.id <= 0) continue;
          _presenceByUserId[details.id] = PresenceUtils.normalize(
            details.presenceStatus,
          );
        }
        for (final request in _outgoingFriendRequests) {
          final details = request.friendDetails;
          if (details == null || details.id <= 0) continue;
          _presenceByUserId[details.id] = PresenceUtils.normalize(
            details.presenceStatus,
          );
        }
      },
      silent: silent,
      fallbackMessage: 'Impossible de charger les demandes d\'amis',
    );
  }

  Future<void> refreshBlockedUsers({bool silent = false}) async {
    await _wrap(
      () async {
        final blockedFromApi = await _friendsRepository.readBlockedUsers();
        final blockedFromFriends = _friends
            .where((friend) => _isBlockedFriendStatus(friend.status))
            .map((friend) => friend.friendDetails)
            .whereType<UserModel>();
        final byId = <int, UserModel>{
          for (final user in blockedFromApi) user.id: user,
        };
        for (final user in blockedFromFriends) {
          if (user.id > 0) byId[user.id] = user;
        }
        _blockedUsers = byId.values.toList(growable: false);
        for (final user in _blockedUsers) {
          if (user.id <= 0) continue;
          _presenceByUserId[user.id] = PresenceUtils.normalize(
            user.presenceStatus,
          );
        }
      },
      silent: silent,
      fallbackMessage: 'Impossible de charger les utilisateurs bloqués',
    );
  }

  Future<void> refreshUsers({bool silent = false}) async {
    await _wrap(
      () async {
        _allUsers = await _accountRepository.readAllUsers();
        for (final user in _allUsers) {
          if (user.id <= 0) continue;
          _presenceByUserId[user.id] = PresenceUtils.normalize(
            user.presenceStatus,
          );
        }
      },
      silent: silent,
      fallbackMessage: 'Impossible de charger les utilisateurs',
    );
  }

  Future<void> refreshChannels({bool silent = false}) async {
    await _wrap(
      () async {
        final previousById = <int, ChannelModel>{
          for (final channel in _channels) channel.channelId: channel,
        };
        final fetched = await _channelRepository.readUserChannels(
          filter: 'joined',
        );
        _channels = fetched
            .map((channel) {
              final previous = previousById[channel.channelId];
              final hasDescription =
                  channel.description?.trim().isNotEmpty == true;
              if (hasDescription || previous == null) return channel;
              return channel.copyWith(description: previous.description);
            })
            .toList(growable: false);
        if (_selectedChannel != null) {
          final match = _channels.where(
            (it) => it.channelId == _selectedChannel!.channelId,
          );
          if (match.isEmpty) {
            _selectedChannel = null;
            _messages = const [];
            _channelMembers = const [];
          } else {
            _selectedChannel = match.first;
          }
        }
      },
      silent: silent,
      fallbackMessage: 'Impossible de charger les channels',
    );
  }

  Future<void> refreshPublicChannels({
    String filter = 'all',
    bool silent = false,
  }) async {
    await _wrap(
      () async {
        _publicChannels = await loadJoinDirectoryChannels(filter: filter);
      },
      silent: silent,
      fallbackMessage: 'Impossible de charger les channels publics',
    );
  }

  Future<List<ChannelModel>> loadJoinDirectoryChannels({
    String filter = 'all',
  }) async {
    final normalizedFilter = _normalizePublicChannelFilter(filter);
    final fetched = await _channelRepository.readUserChannels(
      filter: normalizedFilter,
    );
    if (normalizedFilter == 'discover') {
      return _buildDiscoverTopChannels(fetched);
    }
    if (normalizedFilter == 'joined') {
      return _excludePrivateDmChannels(fetched);
    }
    return fetched;
  }

  Future<void> refreshShop({bool silent = false}) async {
    await _wrap(
      () async {
        _shopItems = await _shopRepository.readAll();
      },
      silent: silent,
      fallbackMessage: 'Impossible de charger la boutique',
    );
  }

  Future<void> refreshInventory({bool silent = false}) async {
    await _wrap(
      () async {
        _inventoryItems = await _inventoryRepository.readAll();
      },
      silent: silent,
      fallbackMessage: 'Impossible de charger l\'inventaire',
    );
  }

  Future<void> refreshInvoices({bool silent = false}) async {
    await _wrap(
      () async {
        _invoices = await _invoiceRepository.readAll();
      },
      silent: silent,
      fallbackMessage: 'Impossible de charger les factures',
    );
  }

  Future<FriendModel?> addFriendByUsername(
    String username, {
    int? userId,
  }) async {
    final normalizedUsername = username.trim();
    if (normalizedUsername.isEmpty) return null;
    if (isFriendRequestPending(userId: userId, username: normalizedUsername)) {
      _errorMessage = 'Demande deja en attente pour cet utilisateur.';
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await _friendsRepository.addByUsername(
        normalizedUsername,
      );
      await Future.wait([
        refreshFriends(silent: true),
        refreshFriendRequests(silent: true),
        refreshBlockedUsers(silent: true),
      ]);
      return created;
    } catch (e) {
      _errorMessage = ApiErrorParser.parse(e, fallback: 'Ajout ami impossible');
      await Future.wait([
        refreshFriendRequests(silent: true),
        refreshBlockedUsers(silent: true),
      ]);
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> respondToIncomingFriendRequest({
    required int requestId,
    required String status,
  }) async {
    await _wrap(() async {
      await _friendsRepository.respondToRequest(
        requestId: requestId,
        status: status,
      );
      await Future.wait([
        refreshFriends(silent: true),
        refreshFriendRequests(silent: true),
        refreshBlockedUsers(silent: true),
      ]);
    }, fallbackMessage: 'Impossible de repondre a la demande');
  }

  Future<void> cancelOutgoingFriendRequest(int requestId) async {
    await _wrap(() async {
      await _friendsRepository.cancelOutgoingRequest(requestId);
      await refreshFriendRequests(silent: true);
    }, fallbackMessage: 'Impossible d\'annuler la demande');
  }

  Future<void> unblockUser(int userId) async {
    await _wrap(() async {
      await _friendsRepository.unblockUserById(userId);
      await Future.wait([
        refreshBlockedUsers(silent: true),
        refreshFriendRequests(silent: true),
      ]);
    }, fallbackMessage: 'Impossible de debloquer cet utilisateur');
  }

  Future<void> blockUser(int userId) async {
    await _wrap(() async {
      await _friendsRepository.blockUserById(userId);
      await Future.wait([
        refreshBlockedUsers(silent: true),
        refreshFriendRequests(silent: true),
      ]);
    }, fallbackMessage: 'Impossible de bloquer cet utilisateur');
  }

  Future<void> deleteFriend(int friendId) async {
    await _wrap(() async {
      await _friendsRepository.deleteById(friendId);
      _friends = await _friendsRepository.readAll();
    }, fallbackMessage: 'Suppression ami impossible');
  }

  Future<void> createChannel({
    required String name,
    required String description,
    String channelType = 'GROUP',
    String visibility = 'PUBLIC',
    List<int>? memberIds,
    String? imageFilePath,
  }) async {
    await _wrap(() async {
      final created = await _channelRepository.create(
        channelType: channelType,
        name: name,
        description: description,
        visibility: visibility,
        memberIds: memberIds,
        imageFilePath: imageFilePath,
      );
      await refreshChannels(silent: true);
      final channelToOpen = _channels.firstWhere(
        (channel) => channel.channelId == created.channelId,
        orElse: () => created,
      );
      await selectChannel(channelToOpen);
    }, fallbackMessage: 'Creation de channel impossible');
  }

  Future<void> createGroupChannel({
    required String name,
    String description = '',
    required String visibility,
    String? imageFilePath,
  }) async {
    await createChannel(
      name: name,
      description: description,
      channelType: 'GROUP',
      visibility: visibility,
      imageFilePath: imageFilePath,
    );
  }

  Future<void> createPrivateDm({required int targetUserId}) async {
    await _wrap(() async {
      final created = await _channelRepository.create(
        channelType: 'PRIVATE_DM',
        memberIds: [targetUserId],
      );
      await refreshChannels(silent: true);
      final channelToOpen = _channels.firstWhere(
        (channel) => channel.channelId == created.channelId,
        orElse: () => created,
      );
      await selectChannel(channelToOpen);
    }, fallbackMessage: 'Creation de conversation privee impossible');
  }

  Future<void> selectChannel(ChannelModel channel) async {
    final userId = _authController.user?.id;
    if (userId == null) return;

    final previousChannelId = _selectedChannel?.channelId;
    if (previousChannelId != null && previousChannelId != channel.channelId) {
      _socketService.leaveChannel(channelId: previousChannelId, userId: userId);
    }

    _selectedChannel = channel;
    _isLoadingMessages = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _socketService.joinChannel(channelId: channel.channelId, userId: userId);
      final responses = await Future.wait([
        _channelRepository.readChannelMessages(channel.channelId),
        _channelRepository.readChannelUsers(channel.channelId),
      ]);
      _messages = responses[0] as List<ChannelMessageModel>;
      _channelMembers = responses[1] as List<UserModel>;
      await refreshChannels(silent: true);
    } catch (e) {
      _errorMessage = ApiErrorParser.parse(
        e,
        fallback: 'Impossible de charger la conversation',
      );
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String content) async {
    final selected = _selectedChannel;
    final userId = _authController.user?.id;
    final normalized = content.trim();
    if (selected == null || userId == null || normalized.isEmpty) return;
    _messageError = null;
    _socketService.sendPrivateMessage(
      senderId: userId,
      content: normalized,
      channelId: selected.channelId,
    );
    notifyListeners();
  }

  Future<void> sendMessageWithImage({
    required String? imagePath,
    List<int>? imageBytes,
    String? imageFileName,
    String content = '',
  }) async {
    final selected = _selectedChannel;
    final userId = _authController.user?.id;
    if (selected == null || userId == null) return;
    if ((imagePath == null || imagePath.isEmpty) && imageBytes == null) return;

    _messageError = null;
    notifyListeners();

    try {
      final message = await _privateMessageRepository.sendWithImage(
        channelId: selected.channelId,
        content: content,
        imageFilePath: imagePath,
        imageBytes: imageBytes,
        imageFileName: imageFileName,
      );
      final alreadyExists = _messages.any(
        (m) => m.messageId == message.messageId,
      );
      if (!alreadyExists) {
        _messages = [..._messages, message];
        notifyListeners();
      }
    } catch (e) {
      _messageError = ApiErrorParser.parse(
        e,
        fallback: 'Envoi image impossible',
      );
      notifyListeners();
    }
  }

  Future<void> updateMessage({
    required int messageId,
    required String content,
  }) async {
    await _wrap(() async {
      final updated = await _privateMessageRepository.update(
        messageId: messageId,
        content: content,
      );
      _messages = _messages
          .map((message) {
            if (message.messageId == messageId) return updated;
            return message;
          })
          .toList(growable: false);
    }, fallbackMessage: 'Modification du message impossible');
  }

  Future<void> deleteMessage(int messageId) async {
    await _wrap(() async {
      await _privateMessageRepository.delete(messageId);
      _messages = _messages
          .where((message) => message.messageId != messageId)
          .toList(growable: false);
    }, fallbackMessage: 'Suppression du message impossible');
  }

  Future<void> inviteUsersToSelectedChannel(List<int> userIds) async {
    final selected = _selectedChannel;
    if (selected == null) return;
    if (selected.channelType.trim().toUpperCase() == 'PRIVATE_DM') {
      _errorMessage = 'Invitation impossible sur une conversation privee.';
      notifyListeners();
      return;
    }
    await _wrap(() async {
      for (final userId in userIds) {
        await _channelRepository.invite(
          channelId: selected.channelId,
          userId: userId,
        );
      }
      _channelMembers = await _channelRepository.readChannelUsers(
        selected.channelId,
      );
    }, fallbackMessage: 'Invitation impossible');
  }

  Future<void> leaveSelectedChannel() async {
    final selected = _selectedChannel;
    final userId = _authController.user?.id;
    if (selected == null || userId == null) return;
    if (selected.channelType.trim().toUpperCase() == 'PRIVATE_DM') {
      _errorMessage = 'Impossible de quitter une conversation privee.';
      notifyListeners();
      return;
    }
    await _wrap(() async {
      await _channelRepository.leaveChannel(selected.channelId);
      _socketService.leaveChannel(
        channelId: selected.channelId,
        userId: userId,
      );
      _selectedChannel = null;
      _messages = const [];
      _channelMembers = const [];
      await refreshChannels(silent: true);
    }, fallbackMessage: 'Impossible de quitter le channel');
  }

  Future<void> deleteSelectedChannel() async {
    final selected = _selectedChannel;
    if (selected == null) return;
    await _wrap(() async {
      await _channelRepository.deleteChannel(selected.channelId);
      _selectedChannel = null;
      _messages = const [];
      _channelMembers = const [];
      await refreshChannels(silent: true);
    }, fallbackMessage: 'Suppression du channel impossible');
  }

  Future<void> joinPublicChannel(
    int channelId, {
    String publicFilter = 'all',
  }) async {
    await _wrap(() async {
      await _channelRepository.joinPublic(channelId);
      await Future.wait([
        refreshChannels(silent: true),
        refreshPublicChannels(filter: publicFilter, silent: true),
      ]);
    }, fallbackMessage: 'Impossible de rejoindre ce channel public');
  }

  Future<void> joinByInviteCode(String code) async {
    await _wrap(() async {
      final joinedChannelId = await _channelRepository.joinByInvite(code);
      await refreshChannels(silent: true);
      final channelToOpen = _channels.firstWhere(
        (channel) => channel.channelId == joinedChannelId,
      );
      await selectChannel(channelToOpen);
    }, fallbackMessage: 'Invitation invalide ou expiree');
  }

  Future<Map<String, dynamic>?> createInviteLinkForSelectedChannel({
    required String mode,
    int? expiresInMinutes,
  }) async {
    final selected = _selectedChannel;
    if (selected == null) return null;
    try {
      return await _channelRepository.createInviteLink(
        channelId: selected.channelId,
        mode: mode,
        expiresInMinutes: expiresInMinutes,
      );
    } catch (e) {
      _errorMessage = ApiErrorParser.parse(
        e,
        fallback: 'Creation du lien d invitation impossible',
      );
      notifyListeners();
      return null;
    }
  }

  Future<void> updateSelectedChannelCover(String imageFilePath) async {
    final selected = _selectedChannel;
    if (selected == null) return;
    await _wrap(() async {
      await _channelRepository.updateCover(
        channelId: selected.channelId,
        imageFilePath: imageFilePath,
      );
      await refreshChannels(silent: true);
      final refreshed = _channels.where(
        (channel) => channel.channelId == selected.channelId,
      );
      if (refreshed.isNotEmpty) {
        _selectedChannel = refreshed.first;
      }
    }, fallbackMessage: 'Mise a jour de la couverture impossible');
  }

  Future<void> updateSelectedGroup({
    String? name,
    String? description,
    String? visibility,
    String? imageFilePath,
  }) async {
    final selected = _selectedChannel;
    if (selected == null) return;
    await _wrap(() async {
      final normalizedName = name?.trim();
      final normalizedDescription = description?.trim();
      final normalizedVisibility = visibility?.trim().toUpperCase();

      _selectedChannel = selected.copyWith(
        name: normalizedName ?? selected.name,
        description: normalizedDescription ?? selected.description,
        visibility: normalizedVisibility ?? selected.visibility,
      );
      _channels = _channels
          .map(
            (channel) => channel.channelId == selected.channelId
                ? channel.copyWith(
                    name: normalizedName ?? channel.name,
                    description: normalizedDescription ?? channel.description,
                    visibility: normalizedVisibility ?? channel.visibility,
                  )
                : channel,
          )
          .toList(growable: false);
      notifyListeners();

      if (normalizedName != null ||
          normalizedDescription != null ||
          normalizedVisibility != null) {
        await _channelRepository.updateGroup(
          channelId: selected.channelId,
          name: normalizedName,
          description: normalizedDescription,
          visibility: normalizedVisibility,
        );
      }

      if (imageFilePath != null && imageFilePath.trim().isNotEmpty) {
        await _channelRepository.updateCover(
          channelId: selected.channelId,
          imageFilePath: imageFilePath,
        );
      }

      await refreshChannels(silent: true);
      final refreshed = _channels.where(
        (channel) => channel.channelId == selected.channelId,
      );
      if (refreshed.isNotEmpty) {
        _selectedChannel = refreshed.first;
      }
    }, fallbackMessage: 'Mise a jour du groupe impossible');
  }

  void closeSelectedChannelView() {
    _selectedChannel = null;
    _messages = const [];
    _channelMembers = const [];
    notifyListeners();
  }

  Future<String?> startCheckout(int articleId) async {
    try {
      final url = await _paymentRepository.createCheckout(articleId);
      if (url.isEmpty) throw Exception('URL de paiement vide');
      return url;
    } catch (e) {
      _errorMessage = ApiErrorParser.parse(e, fallback: 'Paiement impossible');
      notifyListeners();
      return null;
    }
  }

  Future<PaymentConfirmationModel?> confirmPayment(String sessionId) async {
    try {
      final confirmation = await _paymentRepository.confirm(sessionId);
      await Future.wait([
        refreshInventory(silent: true),
        refreshInvoices(silent: true),
        _refreshCurrentUser(),
      ]);
      notifyListeners();
      return confirmation;
    } catch (e) {
      _errorMessage = ApiErrorParser.parse(
        e,
        fallback: 'Confirmation du paiement impossible',
      );
      notifyListeners();
      return null;
    }
  }

  Future<void> activateInventoryItem(int itemId, bool active) async {
    await _wrap(() async {
      await _inventoryRepository.updateStatus(itemId: itemId, active: active);
      _inventoryItems = await _inventoryRepository.readAll();
      await _refreshCurrentUser();
    }, fallbackMessage: 'Activation impossible');
  }

  Future<String?> sendInvoiceByEmail(int invoiceId) async {
    try {
      return await _invoiceRepository.sendInvoiceByEmail(invoiceId);
    } catch (e) {
      _errorMessage = ApiErrorParser.parse(
        e,
        fallback: 'Envoi de facture impossible',
      );
      notifyListeners();
      return null;
    }
  }

  Future<void> updateProfile({
    required String username,
    required String email,
    String? bio,
    bool? allowNonFriendDms,
    String? avatarFilePath,
    Uint8List? avatarBytes,
    String? avatarFileName,
    bool deleteAvatar = false,
  }) async {
    await _wrap(() async {
      final updated = await _accountRepository.updateProfile(
        username: username,
        email: email,
        bio: bio,
        allowNonFriendDms: allowNonFriendDms,
        avatarFilePath: avatarFilePath,
        avatarBytes: avatarBytes,
        avatarFileName: avatarFileName,
        deleteAvatar: deleteAvatar,
      );
      _authController.setUser(updated);
    }, fallbackMessage: 'Mise a jour profil impossible');
  }

  Future<void> updateMyPresenceStatus(String presenceStatus) async {
    await _wrap(() async {
      final normalized = PresenceUtils.normalize(presenceStatus);
      await _accountRepository.updatePresenceStatus(normalized);
      final me = _authController.user;
      if (me == null) return;
      _presenceByUserId[me.id] = normalized;
      if (normalized == PresenceUtils.dnd ||
          normalized == PresenceUtils.invisible) {
        _manualPresenceOverride = normalized;
      } else {
        _manualPresenceOverride = null;
      }
      _authController.setUser(me.copyWith(presenceStatus: normalized));
    }, fallbackMessage: 'Mise a jour du statut impossible');
  }

  Future<bool> openChannelById(int channelId) async {
    if (channelId <= 0) return false;
    ChannelModel? target;
    for (final channel in _channels) {
      if (channel.channelId == channelId) {
        target = channel;
        break;
      }
    }
    if (target == null) {
      await refreshChannels(silent: true);
      for (final channel in _channels) {
        if (channel.channelId == channelId) {
          target = channel;
          break;
        }
      }
    }
    if (target == null) {
      _errorMessage = 'Conversation introuvable.';
      notifyListeners();
      return false;
    }
    await selectChannel(target);
    return _selectedChannel?.channelId == channelId;
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    await _wrap(() async {
      await _accountRepository.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmNewPassword: confirmNewPassword,
      );
    }, fallbackMessage: 'Mise a jour du mot de passe impossible');
  }

  Future<void> deleteAccount() async {
    await _wrap(() async {
      await _accountRepository.deleteAccount();
      await _authController.logout();
    }, fallbackMessage: 'Suppression du compte impossible');
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearMessageError() {
    if (_messageError == null) return;
    _messageError = null;
    notifyListeners();
  }

  void markAllNotificationsAsRead() {
    if (_notifications.isEmpty) return;
    var didChange = false;
    final nextReadIds = <String>{..._readNotificationIds};
    final next = _notifications.map((item) {
      nextReadIds.add(item.id);
      if (item.isRead) return item;
      didChange = true;
      return item.copyWith(isRead: true);
    }).toList(growable: false);
    if (!didChange && nextReadIds.length == _readNotificationIds.length) return;
    _notifications = next;
    _readNotificationIds = nextReadIds;
    _persistReadNotificationIds();
    notifyListeners();
  }

  void _handleAuthChange() {
    final currentUserId = _authController.user?.id;
    if (currentUserId == null) {
      if (_activeUserId != null) {
        _sendInvisibleAndDisconnect();
        _resetState();
      }
      return;
    }
    if (_activeUserId == currentUserId) return;
    _activeUserId = currentUserId;
    _bootForLoggedInUser();
  }

  Future<void> _bootForLoggedInUser() async {
    _socketService.connect(
      authToken: _apiClient.authToken,
      onNewMessage: _onNewMessageFromSocket,
      onFriendRequestReceived: _onFriendRequestReceivedFromSocket,
      onMessageError: _onMessageErrorFromSocket,
      onLocationSnapshot: _onLocationSnapshotFromSocket,
      onLocationUpdate: _onLocationUpdateFromSocket,
      onLocationRemove: _onLocationRemoveFromSocket,
      onPresenceUpdated: _onPresenceUpdatedFromSocket,
    );
    _socketService.requestLiveLocationsSnapshot();
    await refreshAll();
    await _setupPushNotifications();
    await _applyLifecyclePresence(
      WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed,
    );
  }

  void _onNewMessageFromSocket(ChannelMessageModel message) {
    _pushNewMessageNotification(message);
    if (_selectedChannel == null) {
      refreshChannels(silent: true);
      return;
    }
    final enriched = ChannelMessageModel(
      messageId: message.messageId,
      content: message.content,
      channelId: _selectedChannel!.channelId,
      senderId: message.senderId,
      status: message.status,
      createdAt: message.createdAt,
      sender: message.sender,
    );
    _messages = [..._messages, enriched];
    notifyListeners();
    refreshChannels(silent: true);
  }

  void _onFriendRequestReceivedFromSocket(Map<String, dynamic> payload) {
    final senderRaw = payload['sender'];
    final sender = senderRaw is Map<String, dynamic>
        ? senderRaw
        : senderRaw is Map
        ? Map<String, dynamic>.from(senderRaw)
        : const <String, dynamic>{};

    final senderId = _toInt(sender['id'] ?? sender['userId'] ?? sender['user_id']);
    final meId = _authController.user?.id;
    if (meId != null && senderId == meId) return;

    final username = (sender['username'] ?? 'Utilisateur').toString().trim();
    final createdAt = _parseDate(
      payload['createdAt'] ?? payload['created_at'] ?? payload['date'],
    );
    final requestId = _toInt(payload['requestId'] ?? payload['request_id']);

    _prependNotification(
      AppNotificationModel(
        id: 'fr-$requestId-${createdAt.microsecondsSinceEpoch}',
        type: AppNotificationType.friendRequest,
        title: "Vous avez recu une demande d'ami de $username",
        subtitle: _formatNotificationTime(createdAt),
        createdAt: createdAt,
        avatarUrl: sender['avatar']?.toString(),
        relatedUserId: senderId > 0 ? senderId : null,
      ),
    );
    refreshFriendRequests(silent: true);
  }

  void _onMessageErrorFromSocket(String message) {
    final normalized = message.trim();
    _messageError = normalized.isEmpty
        ? 'DM impossible: vous devez etre ami actif ou activer les DM non-amis.'
        : normalized;
    notifyListeners();
  }

  void publishMyLiveLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
  }) {
    final me = _authController.user;
    if (me == null) return;
    final previous = _liveLocationsByUserId[me.id];
    final hasMovedEnough =
        previous == null ||
        _distanceInMeters(
              previous.latitude,
              previous.longitude,
              latitude,
              longitude,
            ) >=
            3;
    if (!hasMovedEnough) return;
    _liveLocationsByUserId[me.id] = LiveUserLocationModel(
      userId: me.id,
      username: me.username,
      avatar: me.avatar,
      latitude: latitude,
      longitude: longitude,
      updatedAt: DateTime.now().toUtc(),
    );
    _socketService.publishLiveLocation(
      userId: me.id,
      username: me.username,
      avatar: me.avatar,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
    );
    notifyListeners();
  }

  void stopMyLiveLocationSharing() {
    final me = _authController.user;
    if (me == null) return;
    _liveLocationsByUserId.remove(me.id);
    _socketService.stopLiveLocationSharing(userId: me.id);
    notifyListeners();
  }

  void _onLocationSnapshotFromSocket(List<dynamic> payload) {
    final meId = _authController.user?.id;
    final next = <int, LiveUserLocationModel>{};
    for (final entry in payload) {
      if (entry is! Map) continue;
      final model = LiveUserLocationModel.fromJson(
        Map<String, dynamic>.from(entry),
      );
      if (!_isLocationPayloadValid(model)) continue;
      next[model.userId] = model;
    }
    if (meId != null && _liveLocationsByUserId.containsKey(meId)) {
      next[meId] = _liveLocationsByUserId[meId]!;
    }
    _liveLocationsByUserId
      ..clear()
      ..addAll(next);
    notifyListeners();
  }

  void _onLocationUpdateFromSocket(Map<String, dynamic> payload) {
    final model = LiveUserLocationModel.fromJson(payload);
    if (!_isLocationPayloadValid(model)) return;
    _liveLocationsByUserId[model.userId] = model;
    notifyListeners();
  }

  void _onLocationRemoveFromSocket(int userId) {
    if (!_liveLocationsByUserId.containsKey(userId)) return;
    _liveLocationsByUserId.remove(userId);
    notifyListeners();
  }

  void _onPresenceUpdatedFromSocket(Map<String, dynamic> payload) {
    final rawUserId = payload['userId'] ?? payload['user_id'] ?? payload['id'];
    final rawStatus = payload['presence_status'] ?? payload['presenceStatus'];
    int userId = 0;
    if (rawUserId is int) {
      userId = rawUserId;
    } else if (rawUserId is num) {
      userId = rawUserId.toInt();
    } else if (rawUserId is String) {
      userId = int.tryParse(rawUserId) ?? 0;
    }
    if (userId <= 0) return;

    final normalized = PresenceUtils.normalize(rawStatus?.toString());
    _presenceByUserId[userId] = normalized;

    final me = _authController.user;
    if (me != null && me.id == userId) {
      _authController.setUser(me.copyWith(presenceStatus: normalized));
      return;
    }
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_authController.isLoggedIn) return;
    if (_activeUserId == null) return;
    _applyLifecyclePresence(state);
  }

  Future<void> _applyLifecyclePresence(AppLifecycleState state) async {
    if (_manualPresenceOverride == PresenceUtils.dnd ||
        _manualPresenceOverride == PresenceUtils.invisible) {
      return;
    }
    switch (state) {
      case AppLifecycleState.resumed:
        await _setPresenceSilently(PresenceUtils.online);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        await _setPresenceSilently(PresenceUtils.idle);
        break;
      case AppLifecycleState.detached:
        await _setPresenceSilently(PresenceUtils.invisible);
        _socketService.disconnect();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _setPresenceSilently(String status) async {
    final me = _authController.user;
    if (me == null || me.id <= 0) return;
    final normalized = PresenceUtils.normalize(status);
    final current = PresenceUtils.normalize(_presenceByUserId[me.id]);
    if (current == normalized) return;

    try {
      await _accountRepository.updatePresenceStatus(normalized);
      _presenceByUserId[me.id] = normalized;
      _authController.setUser(me.copyWith(presenceStatus: normalized));
    } catch (_) {
      // Keep lifecycle transitions best-effort without surfacing noisy errors.
    }
  }

  void _sendInvisibleAndDisconnect() {
    final me = _authController.user;
    if (me != null && me.id > 0) {
      _accountRepository
          .updatePresenceStatus(PresenceUtils.invisible)
          .catchError((_) {});
    }
    final token = _lastRegisteredPushToken;
    if (token != null && token.isNotEmpty) {
      _accountRepository.unregisterPushToken(token: token).catchError((_) {});
    }
    _pushNotificationService.deleteToken();
    _socketService.disconnect();
  }

  Future<void> _setupPushNotifications() async {
    final ready = await _pushNotificationService.initializeForDevice();
    if (!ready) return;
    await _syncCurrentPushToken();

    _pushTokenRefreshSubscription?.cancel();
    _pushTokenRefreshSubscription = _pushNotificationService.onTokenRefresh
        .listen((token) {
          _syncPushToken(token);
        });

    _pushOpenedAppSubscription?.cancel();
    _pushOpenedAppSubscription = _pushNotificationService.onMessageOpenedApp
        .listen(_handlePushMessageOpen);

    _pushForegroundMessageSubscription?.cancel();
    _pushForegroundMessageSubscription = _pushNotificationService.onMessage
        .listen(_handleForegroundPushMessage);

    final initialMessage = await _pushNotificationService.getInitialMessage();
    if (initialMessage != null) {
      _handlePushMessageOpen(initialMessage);
    }
  }

  Future<void> _syncCurrentPushToken() async {
    final token = await _pushNotificationService.getToken();
    if (token == null || token.trim().isEmpty) return;
    await _syncPushToken(token);
  }

  Future<void> _syncPushToken(String token) async {
    final me = _authController.user;
    final normalized = token.trim();
    if (me == null || normalized.isEmpty) return;
    if (_lastRegisteredPushToken == normalized) return;
    try {
      await _accountRepository.registerPushToken(
        token: normalized,
        platform: AccountRepository.currentDevicePlatform(),
      );
      _lastRegisteredPushToken = normalized;
    } catch (_) {
      // Keep push token sync best-effort.
    }
  }

  void _handleForegroundPushMessage(dynamic message) {
    if (message is! RemoteMessage) return;
    _appendPushNotification(message);
  }

  void _handlePushMessageOpen(dynamic message) {
    if (message is! RemoteMessage) return;
    _appendPushNotification(message);
    final channelId = _toInt(
      message.data['channelId'] ??
          message.data['channel_id'] ??
          message.data['conversation_id'],
    );
    if (channelId > 0) {
      openChannelById(channelId);
    }
  }

  void _appendPushNotification(RemoteMessage message) {
    final data = message.data;
    final eventType = (data['event'] ?? data['type'] ?? '').toString().trim();
    if (eventType == 'newMessage') {
      final senderId = _toInt(data['senderId'] ?? data['sender_id']);
      final meId = _authController.user?.id;
      if (meId != null && senderId == meId) return;
      final senderName = (data['senderUsername'] ?? data['sender_username'] ?? '')
          .toString()
          .trim();
      final channelId = _toInt(data['channelId'] ?? data['channel_id']);
      final now = DateTime.now();
      _prependNotification(
        AppNotificationModel(
          id: 'push-msg-${data['id'] ?? now.microsecondsSinceEpoch}',
          type: AppNotificationType.newMessage,
          title: senderName.isEmpty
              ? 'Vous avez recu un nouveau message'
              : 'Vous avez recu un nouveau message de $senderName',
          subtitle: _formatNotificationTime(now),
          createdAt: now,
          relatedUserId: senderId > 0 ? senderId : null,
          relatedChannelId: channelId > 0 ? channelId : null,
        ),
      );
      return;
    }
    if (eventType == 'friendRequestReceived') {
      final senderId = _toInt(data['senderId'] ?? data['sender_id']);
      final senderName = (data['senderUsername'] ?? data['sender_username'] ?? '')
          .toString()
          .trim();
      final now = DateTime.now();
      _prependNotification(
        AppNotificationModel(
          id: 'push-fr-${data['requestId'] ?? now.microsecondsSinceEpoch}',
          type: AppNotificationType.friendRequest,
          title: senderName.isEmpty
              ? "Vous avez recu une demande d'ami"
              : "Vous avez recu une demande d'ami de $senderName",
          subtitle: _formatNotificationTime(now),
          createdAt: now,
          relatedUserId: senderId > 0 ? senderId : null,
        ),
      );
    }
  }

  bool _isLocationPayloadValid(LiveUserLocationModel value) {
    if (value.userId <= 0) return false;
    if (value.latitude < -90 || value.latitude > 90) return false;
    if (value.longitude < -180 || value.longitude > 180) return false;
    return true;
  }

  double _distanceInMeters(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  double _toRadians(double deg) => deg * 0.017453292519943295;

  void _pushNewMessageNotification(ChannelMessageModel message) {
    final meId = _authController.user?.id;
    final senderId = message.senderId ?? message.sender?.id;
    if (meId != null && senderId == meId) return;

    final selectedId = _selectedChannel?.channelId;
    if (selectedId != null && selectedId == message.channelId) {
      // User is already in this conversation: no toast/notification needed.
      return;
    }

    final senderName = message.sender?.username.trim();
    final safeSenderName = (senderName == null || senderName.isEmpty)
        ? 'Utilisateur'
        : senderName;
    final createdAt = message.createdAt ?? DateTime.now();

    _prependNotification(
      AppNotificationModel(
        id: 'msg-${message.messageId}-${createdAt.microsecondsSinceEpoch}',
        type: AppNotificationType.newMessage,
        title: 'Vous avez recu un nouveau message de $safeSenderName',
        subtitle: _formatNotificationTime(createdAt),
        createdAt: createdAt,
        avatarUrl: message.sender?.avatar ?? message.imageUrl,
        relatedUserId: senderId,
        relatedChannelId: message.channelId > 0 ? message.channelId : null,
      ),
    );
  }

  void _prependNotification(AppNotificationModel value) {
    final incoming = value.copyWith(isRead: _readNotificationIds.contains(value.id));
    final deduped = _notifications.where((item) => item.id != incoming.id);
    final next = <AppNotificationModel>[incoming, ...deduped];
    _notifications = next.take(100).toList(growable: false);
    notifyListeners();
  }

  void _rebuildPendingFriendRequestNotifications() {
    for (final request in _incomingFriendRequests) {
      final status = request.status.trim().toUpperCase();
      if (status != 'PENDING') continue;
      final username =
          request.friendDetails?.username.trim().isNotEmpty == true
          ? request.friendDetails!.username.trim()
          : 'Utilisateur';
      _prependNotification(
        AppNotificationModel(
          id: 'fr-pending-${request.id}',
          type: AppNotificationType.friendRequest,
          title: "Vous avez recu une demande d'ami de $username",
          subtitle: 'En attente',
          createdAt: DateTime.now(),
          avatarUrl: request.friendDetails?.avatar,
          relatedUserId: request.friendId > 0 ? request.friendId : null,
        ),
      );
    }
  }

  void _rebuildChannelUnreadNotifications() {
    for (final channel in _channels) {
      if (channel.unreadCount <= 0) continue;
      final countLabel = channel.unreadCount > 1
          ? '${channel.unreadCount} nouveaux messages'
          : '1 nouveau message';
      _prependNotification(
        AppNotificationModel(
          id: 'ch-unread-${channel.channelId}',
          type: AppNotificationType.newMessage,
          title: countLabel,
          subtitle: channel.name.trim().isEmpty
              ? 'Conversation'
              : channel.name.trim(),
          createdAt: DateTime.now(),
          avatarUrl: channel.dmPeer?.avatar ?? channel.coverImage,
          relatedUserId: channel.dmPeer?.id,
          relatedChannelId: channel.channelId,
        ),
      );
    }
  }

  Future<void> _loadReadNotificationIds() async {
    final meId = _authController.user?.id;
    if (meId == null || meId <= 0) {
      _readNotificationIds = <String>{};
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_readNotificationsStorageKey(meId)) ?? const <String>[];
    _readNotificationIds = stored.toSet();
  }

  Future<void> _persistReadNotificationIds() async {
    final meId = _authController.user?.id;
    if (meId == null || meId <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _readNotificationsStorageKey(meId),
      _readNotificationIds.toList(growable: false),
    );
  }

  String _readNotificationsStorageKey(int userId) =>
      'notifications_read_ids_v1_user_$userId';

  String _formatNotificationTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return "Aujourd'hui a $hour:$minute";
  }

  DateTime _parseDate(dynamic raw) {
    if (raw is DateTime) return raw;
    if (raw is String) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  int _toInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw) ?? 0;
    return 0;
  }

  bool _isActiveFriendStatus(String status) {
    final normalized = status.trim().toUpperCase();
    return normalized == 'ACTIVE';
  }

  bool _isBlockedFriendStatus(String status) {
    final normalized = status.trim().toUpperCase();
    return normalized == 'BLOCKED' || normalized == 'BLOQUED';
  }

  String _normalizePublicChannelFilter(String filter) {
    final normalized = filter.trim().toLowerCase();
    switch (normalized) {
      case 'joined':
      case 'discover':
      case 'all':
        return normalized;
      default:
        return 'all';
    }
  }

  List<ChannelModel> _buildDiscoverTopChannels(List<ChannelModel> channels) {
    final discoverGroups = channels
        .where((channel) {
          final type = channel.channelType.trim().toUpperCase();
          final visibility = channel.visibility.trim().toUpperCase();
          return type == 'GROUP' && visibility == 'PUBLIC';
        })
        .toList(growable: false);

    discoverGroups.sort(
      (a, b) =>
          (b.reputationScore ?? 0).compareTo(a.reputationScore ?? 0),
    );
    return discoverGroups.take(10).toList(growable: false);
  }

  List<ChannelModel> _excludePrivateDmChannels(List<ChannelModel> channels) {
    return channels
        .where(
          (channel) => channel.channelType.trim().toUpperCase() != 'PRIVATE_DM',
        )
        .toList(growable: false);
  }

  Future<void> _refreshCurrentUser() async {
    final me = await _accountRepository.readAccount();
    if (me.id > 0) {
      _presenceByUserId[me.id] = PresenceUtils.normalize(me.presenceStatus);
    }
    _authController.setUser(me);
  }

  Future<void> _wrap(
    Future<void> Function() callback, {
    required String fallbackMessage,
    bool silent = false,
  }) async {
    if (!silent) {
      _isSubmitting = true;
      _errorMessage = null;
      notifyListeners();
    }
    try {
      await callback();
    } catch (e) {
      _errorMessage = ApiErrorParser.parse(e, fallback: fallbackMessage);
    } finally {
      if (!silent) _isSubmitting = false;
      notifyListeners();
    }
  }

  void _resetState() {
    _activeUserId = null;
    _friends = const [];
    _incomingFriendRequests = const [];
    _outgoingFriendRequests = const [];
    _blockedUsers = const [];
    _channels = const [];
    _publicChannels = const [];
    _selectedChannel = null;
    _channelMembers = const [];
    _messages = const [];
    _notifications = const [];
    _readNotificationIds = <String>{};
    _shopItems = const [];
    _inventoryItems = const [];
    _invoices = const [];
    _allUsers = const [];
    _liveLocationsByUserId.clear();
    _presenceByUserId.clear();
    _manualPresenceOverride = null;
    _errorMessage = null;
    _messageError = null;
    _isBootstrapping = false;
    _isLoadingMessages = false;
    _isSubmitting = false;
    _socketService.disconnect();
    _pushTokenRefreshSubscription?.cancel();
    _pushOpenedAppSubscription?.cancel();
    _pushForegroundMessageSubscription?.cancel();
    _pushTokenRefreshSubscription = null;
    _pushOpenedAppSubscription = null;
    _pushForegroundMessageSubscription = null;
    _lastRegisteredPushToken = null;
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authController.removeListener(_authListener);
    _socketService.disconnect();
    _pushTokenRefreshSubscription?.cancel();
    _pushOpenedAppSubscription?.cancel();
    _pushForegroundMessageSubscription?.cancel();
    super.dispose();
  }
}
