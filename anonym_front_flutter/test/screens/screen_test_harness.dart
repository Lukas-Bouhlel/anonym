import 'package:anonym_front_flutter/models/channel_message_model.dart';
import 'package:anonym_front_flutter/models/channel_model.dart';
import 'package:anonym_front_flutter/models/friend_model.dart';
import 'package:anonym_front_flutter/models/inventory_item_model.dart';
import 'package:anonym_front_flutter/models/invoice_model.dart';
import 'package:anonym_front_flutter/models/payment_confirmation_model.dart';
import 'package:anonym_front_flutter/models/shop_item_model.dart';
import 'package:anonym_front_flutter/models/user_model.dart';
import 'package:anonym_front_flutter/providers/app_providers.dart';
import 'package:anonym_front_flutter/providers/auth_providers.dart';
import 'package:anonym_front_flutter/services/account_repository.dart';
import 'package:anonym_front_flutter/services/api_client.dart';
import 'package:anonym_front_flutter/services/auth_repository.dart';
import 'package:anonym_front_flutter/services/channel_repository.dart';
import 'package:anonym_front_flutter/services/friends_repository.dart';
import 'package:anonym_front_flutter/services/inventory_repository.dart';
import 'package:anonym_front_flutter/services/invoice_repository.dart';
import 'package:anonym_front_flutter/services/payment_repository.dart';
import 'package:anonym_front_flutter/services/private_message_repository.dart';
import 'package:anonym_front_flutter/services/push_notification_service.dart';
import 'package:anonym_front_flutter/services/shop_repository.dart';
import 'package:anonym_front_flutter/services/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAccountRepository extends Mock implements AccountRepository {}

class MockApiClient extends Mock implements ApiClient {}

class MockFriendsRepository extends Mock implements FriendsRepository {}

class MockChannelRepository extends Mock implements ChannelRepository {}

class MockPrivateMessageRepository extends Mock
    implements PrivateMessageRepository {}

class MockShopRepository extends Mock implements ShopRepository {}

class MockInventoryRepository extends Mock implements InventoryRepository {}

class MockPaymentRepository extends Mock implements PaymentRepository {}

class MockInvoiceRepository extends Mock implements InvoiceRepository {}

class MockSocketService extends Mock implements SocketService {}

class MockPushNotificationService extends Mock
    implements PushNotificationService {}

void _noopVoidCallback() {}

bool _fallbacksRegistered = false;

void _registerFallbacks() {
  if (_fallbacksRegistered) return;
  registerFallbackValue(_noopVoidCallback);
  _fallbacksRegistered = true;
}

class ScreenTestHarness {
  ScreenTestHarness._({
    required this.authProvider,
    required this.appProvider,
    required this.accountRepository,
    required this.friendsRepository,
    required this.channelRepository,
  });

  final AuthProvider authProvider;
  final AppProvider appProvider;
  final MockAccountRepository accountRepository;
  final MockFriendsRepository friendsRepository;
  final MockChannelRepository channelRepository;

  static Future<ScreenTestHarness> create({
    UserModel currentAccountUser = const UserModel(
      id: 0,
      username: '',
      email: '',
    ),
    List<FriendModel> friends = const [],
    List<FriendModel> incomingRequests = const [],
    List<FriendModel> outgoingRequests = const [],
    List<UserModel> blockedUsers = const [],
    List<UserModel> users = const [],
    List<ChannelModel> joinedChannels = const [],
    List<ChannelModel> publicChannels = const [],
    List<ShopItemModel> shopItems = const [],
    List<InventoryItemModel> inventoryItems = const [],
    List<InvoiceModel> invoices = const [],
  }) async {
    _registerFallbacks();
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final authRepository = MockAuthRepository();
    final accountRepository = MockAccountRepository();
    final apiClient = MockApiClient();
    final friendsRepository = MockFriendsRepository();
    final channelRepository = MockChannelRepository();
    final privateMessageRepository = MockPrivateMessageRepository();
    final shopRepository = MockShopRepository();
    final inventoryRepository = MockInventoryRepository();
    final paymentRepository = MockPaymentRepository();
    final invoiceRepository = MockInvoiceRepository();
    final socketService = MockSocketService();
    final pushNotificationService = MockPushNotificationService();

    when(
      () => authRepository.setSessionExpiredHandler(any()),
    ).thenAnswer((_) {});
    when(() => authRepository.hydrateSession()).thenAnswer((_) async {});
    when(() => authRepository.me()).thenThrow(Exception('No active session'));
    when(() => authRepository.clearLocalSession()).thenAnswer((_) async {});
    when(() => authRepository.logout()).thenAnswer((_) async {});

    when(
      () => accountRepository.readAccount(),
    ).thenAnswer((_) async => currentAccountUser);
    when(() => accountRepository.readAllUsers()).thenAnswer((_) async => users);
    when(() => accountRepository.readUserById(any())).thenAnswer((invocation) {
      final userId = invocation.positionalArguments[0] as int;
      final hydrated = users.where((item) => item.id == userId).toList();
      if (hydrated.isNotEmpty) return Future.value(hydrated.first);
      return Future.value(
        UserModel(
          id: userId,
          username: 'user_$userId',
          email: 'user_$userId@example.test',
        ),
      );
    });
    when(
      () => accountRepository.updatePresenceStatus(any()),
    ).thenAnswer((_) async {});
    when(
      () => accountRepository.registerPushToken(
        token: any(named: 'token'),
        platform: any(named: 'platform'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => accountRepository.unregisterPushToken(token: any(named: 'token')),
    ).thenAnswer((_) async {});

    when(() => apiClient.refreshSession()).thenAnswer((_) async => false);
    when(
      () => apiClient.buildSocketAuthHeaders(),
    ).thenAnswer((_) async => const <String, dynamic>{});
    when(() => apiClient.buildSocketAuthToken()).thenAnswer((_) async => null);
    when(() => apiClient.authToken).thenReturn(null);

    when(() => friendsRepository.readAll()).thenAnswer((_) async => friends);
    when(
      () => friendsRepository.readIncomingRequests(),
    ).thenAnswer((_) async => incomingRequests);
    when(
      () => friendsRepository.readOutgoingRequests(),
    ).thenAnswer((_) async => outgoingRequests);
    when(
      () => friendsRepository.readBlockedUsers(),
    ).thenAnswer((_) async => blockedUsers);
    when(() => friendsRepository.deleteById(any())).thenAnswer((_) async {});
    when(
      () => friendsRepository.respondToRequest(
        requestId: any(named: 'requestId'),
        status: any(named: 'status'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => friendsRepository.cancelOutgoingRequest(any()),
    ).thenAnswer((_) async {});
    when(
      () => friendsRepository.addByUsername(any()),
    ).thenAnswer((_) async => null);

    when(
      () => channelRepository.readUserChannels(filter: any(named: 'filter')),
    ).thenAnswer((invocation) async {
      final filter = invocation.namedArguments[#filter] as String?;
      if (filter == 'joined') return joinedChannels;
      return publicChannels;
    });
    when(
      () => channelRepository.readPublicChannels(),
    ).thenAnswer((_) async => publicChannels);
    when(
      () => channelRepository.readChannelUsers(any()),
    ).thenAnswer((_) async => const <UserModel>[]);
    when(
      () => channelRepository.readChannelMessages(any()),
    ).thenAnswer((_) async => const <ChannelMessageModel>[]);
    when(() => channelRepository.joinPublic(any())).thenAnswer((_) async {});
    when(
      () => channelRepository.createInviteLink(
        channelId: any(named: 'channelId'),
        mode: any(named: 'mode'),
        expiresInMinutes: any(named: 'expiresInMinutes'),
      ),
    ).thenAnswer((_) async => const <String, dynamic>{'code': 'TEST'});
    when(
      () => channelRepository.invite(
        channelId: any(named: 'channelId'),
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => channelRepository.removeMember(
        channelId: any(named: 'channelId'),
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => channelRepository.updateCover(
        channelId: any(named: 'channelId'),
        imageFilePath: any(named: 'imageFilePath'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => channelRepository.updateGroup(
        channelId: any(named: 'channelId'),
        name: any(named: 'name'),
        description: any(named: 'description'),
        visibility: any(named: 'visibility'),
      ),
    ).thenAnswer((_) async {});
    when(() => channelRepository.leaveChannel(any())).thenAnswer((_) async {});
    when(() => channelRepository.deleteChannel(any())).thenAnswer((_) async {});
    when(
      () => channelRepository.joinByInvite(any()),
    ).thenAnswer((_) async => 0);

    when(
      () => privateMessageRepository.sendWithImage(
        channelId: any(named: 'channelId'),
        content: any(named: 'content'),
        imageFilePath: any(named: 'imageFilePath'),
        imageBytes: any(named: 'imageBytes'),
        imageFileName: any(named: 'imageFileName'),
      ),
    ).thenAnswer(
      (_) async =>
          const ChannelMessageModel(messageId: 0, content: '', channelId: 0),
    );
    when(
      () => privateMessageRepository.update(
        messageId: any(named: 'messageId'),
        content: any(named: 'content'),
      ),
    ).thenAnswer(
      (_) async =>
          const ChannelMessageModel(messageId: 0, content: '', channelId: 0),
    );
    when(() => privateMessageRepository.delete(any())).thenAnswer((_) async {});

    when(() => shopRepository.readAll()).thenAnswer((_) async => shopItems);
    when(
      () => inventoryRepository.readAll(),
    ).thenAnswer((_) async => inventoryItems);
    when(() => invoiceRepository.readAll()).thenAnswer((_) async => invoices);
    when(
      () => paymentRepository.createCheckout(any()),
    ).thenAnswer((_) async => 'https://checkout.test');
    when(
      () => paymentRepository.confirm(any()),
    ).thenAnswer((_) async => const PaymentConfirmationModel(message: 'ok'));

    when(() => socketService.isConnected).thenReturn(false);
    when(() => socketService.requestLiveLocationsSnapshot()).thenAnswer((_) {});
    when(() => socketService.disconnect()).thenAnswer((_) {});
    when(
      () => pushNotificationService.initializeForDevice(),
    ).thenAnswer((_) async => false);
    when(
      () => pushNotificationService.getToken(),
    ).thenAnswer((_) async => null);
    when(
      () => pushNotificationService.getInitialMessage(),
    ).thenAnswer((_) async => null);
    when(() => pushNotificationService.deleteToken()).thenAnswer((_) async {});
    when(
      () => pushNotificationService.onTokenRefresh,
    ).thenAnswer((_) => const Stream<String>.empty());
    when(
      () => pushNotificationService.onMessage,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => pushNotificationService.onMessageOpenedApp,
    ).thenAnswer((_) => const Stream.empty());

    final authProvider = AuthProvider(authRepository);
    final appProvider = AppProvider(
      authProvider: authProvider,
      accountRepository: accountRepository,
      apiClient: apiClient,
      friendsRepository: friendsRepository,
      channelRepository: channelRepository,
      privateMessageRepository: privateMessageRepository,
      shopRepository: shopRepository,
      inventoryRepository: inventoryRepository,
      paymentRepository: paymentRepository,
      invoiceRepository: invoiceRepository,
      socketService: socketService,
      pushNotificationService: pushNotificationService,
    );

    return ScreenTestHarness._(
      authProvider: authProvider,
      appProvider: appProvider,
      accountRepository: accountRepository,
      friendsRepository: friendsRepository,
      channelRepository: channelRepository,
    );
  }

  Widget wrapWithProviders(Widget child, {bool withScaffold = true}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<AppProvider>.value(value: appProvider),
      ],
      child: MaterialApp(home: withScaffold ? Scaffold(body: child) : child),
    );
  }

  Future<void> seedJoinedChannels() async {
    await appProvider.refreshChannels(silent: true);
  }

  Future<void> dispose() async {
    appProvider.dispose();
    authProvider.dispose();
  }
}


