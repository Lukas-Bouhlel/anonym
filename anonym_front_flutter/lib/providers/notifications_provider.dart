import 'package:flutter/foundation.dart';

import '../models/app_notification_model.dart';
import 'app_providers.dart';

/// Domain provider for in-app notifications state.
class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider(this._app) {
    _listener = notifyListeners;
    _app.notificationsListenable.addListener(_listener);
  }

  final AppProvider _app;
  late final VoidCallback _listener;

  List<AppNotificationModel> get notifications => _app.notifications;
  int get unreadNotificationsCount => _app.unreadNotificationsCount;

  void markAllNotificationsAsRead() => _app.markAllNotificationsAsRead();

  @override
  void dispose() {
    _app.notificationsListenable.removeListener(_listener);
    super.dispose();
  }
}
