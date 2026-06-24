import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import 'pages/app_page.dart';
import 'providers/app_orchestrator_provider.dart';
import 'providers/app_providers.dart';
import 'providers/auth_providers.dart';
import 'providers/channels_provider.dart';
import 'providers/commerce_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/presence_provider.dart';
import 'providers/social_provider.dart';
import 'services/account_repository.dart';
import 'services/admin_repository.dart';
import 'services/api_client.dart';
import 'services/auth_repository.dart';
import 'services/channel_repository.dart';
import 'services/friends_repository.dart';
import 'services/inventory_repository.dart';
import 'services/invoice_repository.dart';
import 'services/payment_repository.dart';
import 'services/points_repository.dart';
import 'services/private_message_repository.dart';
import 'services/push_notification_service.dart';
import 'services/shop_repository.dart';
import 'services/socket_service.dart';

/// Point d'entrée principal de l'application Flutter.
///
/// Initialise les services partagés (API, repositories, socket, push),
/// configure l'arbre de providers et démarre l'UI via [AnonymApp].
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushNotificationService.initializeFirebase();

  final apiClient = await ApiClient.create();
  final authRepository = AuthRepository(apiClient.dio, apiClient);
  final accountRepository = AccountRepository(apiClient.dio);
  final adminRepository = AdminRepository(apiClient.dio);
  final friendsRepository = FriendsRepository(apiClient.dio);
  final channelRepository = ChannelRepository(apiClient.dio);
  final privateMessageRepository = PrivateMessageRepository(apiClient.dio);
  final shopRepository = ShopRepository(apiClient.dio);
  final inventoryRepository = InventoryRepository(apiClient.dio);
  final paymentRepository = PaymentRepository(apiClient.dio);
  final pointsRepository = PointsRepository(apiClient.dio);
  final invoiceRepository = InvoiceRepository(apiClient.dio);
  final socketService = SocketService();
  final appProviderDependencies = AppProviderDependencies(
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
    pushNotificationService: PushNotificationService(
      (!kIsWeb &&
              (defaultTargetPlatform == TargetPlatform.android ||
                  defaultTargetPlatform == TargetPlatform.iOS))
          ? FirebaseMessaging.instance
          : null,
    ),
  );
  final pushNotificationService =
      appProviderDependencies.pushNotificationService;

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: apiClient),
        Provider.value(value: authRepository),
        Provider.value(value: accountRepository),
        Provider.value(value: adminRepository),
        Provider.value(value: friendsRepository),
        Provider.value(value: channelRepository),
        Provider.value(value: privateMessageRepository),
        Provider.value(value: shopRepository),
        Provider.value(value: inventoryRepository),
        Provider.value(value: paymentRepository),
        Provider.value(value: pointsRepository),
        Provider.value(value: invoiceRepository),
        Provider.value(value: socketService),
        Provider.value(value: pushNotificationService),
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
        ChangeNotifierProxyProvider<AuthProvider, AppProvider>(
          create: (context) => AppProvider(
            authProvider: context.read<AuthProvider>(),
            dependencies: appProviderDependencies,
          ),
          update: (context, authProvider, existingController) {
            return existingController ??
                AppProvider(
                  authProvider: authProvider,
                  dependencies: appProviderDependencies,
                );
          },
        ),
        ChangeNotifierProxyProvider<AppProvider, SocialProvider>(
          create: (context) => SocialProvider(context.read<AppProvider>()),
          update: (context, appProvider, existingProvider) {
            return existingProvider ?? SocialProvider(appProvider);
          },
        ),
        ChangeNotifierProxyProvider<AppProvider, ChannelsProvider>(
          create: (context) => ChannelsProvider(context.read<AppProvider>()),
          update: (context, appProvider, existingProvider) {
            return existingProvider ?? ChannelsProvider(appProvider);
          },
        ),
        ChangeNotifierProxyProvider<AppProvider, PresenceProvider>(
          create: (context) => PresenceProvider(context.read<AppProvider>()),
          update: (context, appProvider, existingProvider) {
            return existingProvider ?? PresenceProvider(appProvider);
          },
        ),
        ChangeNotifierProxyProvider<AppProvider, NotificationsProvider>(
          create: (context) =>
              NotificationsProvider(context.read<AppProvider>()),
          update: (context, appProvider, existingProvider) {
            return existingProvider ?? NotificationsProvider(appProvider);
          },
        ),
        ChangeNotifierProxyProvider<AppProvider, CommerceProvider>(
          create: (context) => CommerceProvider(context.read<AppProvider>()),
          update: (context, appProvider, existingProvider) {
            return existingProvider ?? CommerceProvider(appProvider);
          },
        ),
        ChangeNotifierProxyProvider<AppProvider, AppOrchestratorProvider>(
          create: (context) =>
              AppOrchestratorProvider(context.read<AppProvider>()),
          update: (context, appProvider, existingProvider) {
            return existingProvider ?? AppOrchestratorProvider(appProvider);
          },
        ),
      ],
      child: const AnonymApp(),
    ),
  );
}
