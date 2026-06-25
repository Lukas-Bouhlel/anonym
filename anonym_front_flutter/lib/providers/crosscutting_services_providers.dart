part of 'app_providers.dart';

class _AppProviderMutationService {
  _AppProviderMutationService(this._app);

  final AppProvider _app;

  Future<void> run(
    Future<void> Function() callback, {
    required String fallbackMessage,
    bool silent = false,
  }) async {
    if (!silent) {
      _app._isSubmitting = true;
      _app._errorMessage = null;
      _app._notifyStateChanged();
    }
    try {
      await callback();
    } catch (e) {
      _app._errorMessage = ApiErrorParser.parse(e, fallback: fallbackMessage);
    } finally {
      if (!silent) _app._isSubmitting = false;
      _app._notifyStateChanged();
    }
  }
}

class _AppProviderParsingService {
  int toInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw) ?? 0;
    return 0;
  }

  DateTime parseDate(dynamic raw) {
    if (raw is DateTime) return raw;
    if (raw is String) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  String formatNotificationTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return "Aujourd'hui a $hour:$minute";
  }
}

class _AppProviderNotificationService {
  _AppProviderNotificationService(this._app, this._parsing);

  final AppProvider _app;
  final _AppProviderParsingService _parsing;

  bool get shouldStoreInAppNotifications => !_app._isAppInForeground;

  void handleForegroundPushMessage(dynamic message) {
    if (message is! RemoteMessage) return;
    if (shouldStoreInAppNotifications) {
      appendPushNotification(message);
    }
  }

  void handlePushMessageOpen(dynamic message) {
    if (message is! RemoteMessage) return;
    appendPushNotification(message, forceStore: true);
    final channelId = _parsing.toInt(
      message.data['channelId'] ??
          message.data['channel_id'] ??
          message.data['conversation_id'],
    );
    if (channelId > 0) {
      _app.openChannelById(channelId);
    }
  }

  void appendPushNotification(
    RemoteMessage message, {
    bool forceStore = false,
  }) {
    if (!forceStore && !shouldStoreInAppNotifications) return;
    final data = message.data;
    final eventType = (data['event'] ?? data['type'] ?? '').toString().trim();
    if (eventType == 'newMessage') {
      final senderId = _parsing.toInt(data['senderId'] ?? data['sender_id']);
      final meId = _app._authProvider.user?.id;
      if (meId != null && senderId == meId) return;
      final senderName =
          (data['senderUsername'] ?? data['sender_username'] ?? '')
              .toString()
              .trim();
      final channelId = _parsing.toInt(data['channelId'] ?? data['channel_id']);
      final now = DateTime.now();
      prependNotification(
        AppNotificationModel(
          id: 'push-msg-${data['id'] ?? now.microsecondsSinceEpoch}',
          type: AppNotificationType.newMessage,
          title: senderName.isEmpty
              ? 'Vous avez recu un nouveau message'
              : 'Vous avez recu un nouveau message de $senderName',
          subtitle: _parsing.formatNotificationTime(now),
          createdAt: now,
          relatedUserId: senderId > 0 ? senderId : null,
          relatedChannelId: channelId > 0 ? channelId : null,
        ),
      );
      _app._scheduleRealtimeMessageDerivedRefreshes();
      return;
    }
    if (eventType == 'friendRequestReceived') {
      final senderId = _parsing.toInt(data['senderId'] ?? data['sender_id']);
      final senderName =
          (data['senderUsername'] ?? data['sender_username'] ?? '')
              .toString()
              .trim();
      final now = DateTime.now();
      prependNotification(
        AppNotificationModel(
          id: 'push-fr-${data['requestId'] ?? now.microsecondsSinceEpoch}',
          type: AppNotificationType.friendRequest,
          title: senderName.isEmpty
              ? "Vous avez recu une demande d'ami"
              : "Vous avez recu une demande d'ami de $senderName",
          subtitle: _parsing.formatNotificationTime(now),
          createdAt: now,
          relatedUserId: senderId > 0 ? senderId : null,
        ),
      );
    }
  }

  void pushNewMessageNotification(ChannelMessageModel message) {
    final meId = _app._authProvider.user?.id;
    final senderId = message.senderId ?? message.sender?.id;
    if (meId != null && senderId == meId) return;

    final selectedId = _app._selectedChannel?.channelId;
    if (selectedId != null && selectedId == message.channelId) {
      return;
    }

    final senderName = message.sender?.username.trim();
    final safeSenderName = (senderName == null || senderName.isEmpty)
        ? 'Utilisateur'
        : senderName;
    final createdAt = message.createdAt ?? DateTime.now();

    prependNotification(
      AppNotificationModel(
        id: 'msg-${message.messageId}-${createdAt.microsecondsSinceEpoch}',
        type: AppNotificationType.newMessage,
        title: 'Vous avez recu un nouveau message de $safeSenderName',
        subtitle: _parsing.formatNotificationTime(createdAt),
        createdAt: createdAt,
        avatarUrl: message.sender?.avatar ?? message.imageUrl,
        relatedUserId: senderId,
        relatedChannelId: message.channelId > 0 ? message.channelId : null,
      ),
    );
  }

  void prependNotification(AppNotificationModel value) {
    final incoming = value.copyWith(
      isRead: _app._readNotificationIds.contains(value.id),
    );
    final deduped = _app._notifications.where((item) => item.id != incoming.id);
    final next = <AppNotificationModel>[incoming, ...deduped];
    _app._notifications = next.take(100).toList(growable: false);
    _app._notifyStateChanged();
  }

  Future<void> loadReadNotificationIds() async {
    final meId = _app._authProvider.user?.id;
    if (meId == null || meId <= 0) {
      _app._readNotificationIds = <String>{};
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final stored =
        prefs.getStringList(_readNotificationsStorageKey(meId)) ??
        const <String>[];
    _app._readNotificationIds = stored.toSet();
  }

  Future<void> persistReadNotificationIds() async {
    final meId = _app._authProvider.user?.id;
    if (meId == null || meId <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _readNotificationsStorageKey(meId),
      _app._readNotificationIds.toList(growable: false),
    );
  }

  String _readNotificationsStorageKey(int userId) =>
      'notifications_read_ids_v1_user_$userId';
}
