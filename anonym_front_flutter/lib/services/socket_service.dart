import 'package:socket_io_client/socket_io_client.dart' as io;

import '../models/channel_message_model.dart';
import '../utils/app_config.dart';

class SocketService {
  static const _eventLocationSnapshotCandidates = <String>[
    'location:snapshot',
    'location:usersSnapshot',
    'locations:snapshot',
  ];
  static const _eventLocationUpdateCandidates = <String>[
    'location:update',
    'location:userMoved',
    'locations:update',
  ];
  static const _eventLocationRemoveCandidates = <String>[
    'location:remove',
    'location:userLeft',
    'locations:remove',
  ];

  io.Socket? _socket;

  io.Socket? get socket => _socket;

  bool get isConnected => _socket?.connected ?? false;

  void _log(String message) {
    // ignore: avoid_print
    print('[SOCKET-FLUTTER] $message');
  }

  void connect({
    String? authToken,
    Map<String, dynamic>? authHeaders,
    void Function(dynamic error)? onConnectError,
    void Function(ChannelMessageModel message)? onNewMessage,
    void Function(Map<String, dynamic> payload)? onFriendRequestReceived,
    void Function(Map<String, dynamic> payload)? onFriendRequestSent,
    void Function(Map<String, dynamic> payload)? onFriendRequestResponded,
    void Function(Map<String, dynamic> payload)? onFriendRequestCancelled,
    void Function(Map<String, dynamic> payload)? onFriendshipBlocked,
    void Function(Map<String, dynamic> payload)? onFriendshipUnblocked,
    void Function(Map<String, dynamic> payload)? onFriendshipDeleted,
    void Function(Map<String, dynamic> payload)? onFriendsStateUpdated,
    void Function(Map<String, dynamic> payload)? onChannelInvited,
    void Function(Map<String, dynamic> payload)? onChannelMemberRemoved,
    void Function(Map<String, dynamic> payload)? onUserProfileUpdated,
    void Function(String message)? onMessageError,
    void Function(List<dynamic> payload)? onLocationSnapshot,
    void Function(Map<String, dynamic> payload)? onLocationUpdate,
    void Function(int userId)? onLocationRemove,
    void Function(Map<String, dynamic> payload)? onPresenceUpdated,
  }) {
    _log(
      'connect() existing=${_socket != null} authToken=${authToken != null && authToken.trim().isNotEmpty} headers=${authHeaders?.keys.join(",") ?? "none"}',
    );
    if (_socket != null) {
      _registerMessageErrorListener(onMessageError);
      _registerFriendRequestListener(onFriendRequestReceived);
      _registerSocialEventListener(
        eventName: 'friendRequestSent',
        onEvent: onFriendRequestSent,
      );
      _registerSocialEventListener(
        eventName: 'friendRequestResponded',
        onEvent: onFriendRequestResponded,
      );
      _registerSocialEventListener(
        eventName: 'friendRequestCancelled',
        onEvent: onFriendRequestCancelled,
      );
      _registerSocialEventListener(
        eventName: 'friendshipBlocked',
        onEvent: onFriendshipBlocked,
      );
      _registerSocialEventListener(
        eventName: 'friendshipUnblocked',
        onEvent: onFriendshipUnblocked,
      );
      _registerSocialEventListener(
        eventName: 'friendshipDeleted',
        onEvent: onFriendshipDeleted,
      );
      _registerSocialEventListener(
        eventName: 'friendsStateUpdated',
        onEvent: onFriendsStateUpdated,
      );
      _registerSocialEventListener(
        eventName: 'channelInvited',
        onEvent: onChannelInvited,
      );
      _registerSocialEventListener(
        eventName: 'channelMemberRemoved',
        onEvent: onChannelMemberRemoved,
      );
      _registerSocialEventListener(
        eventName: 'userProfileUpdated',
        onEvent: onUserProfileUpdated,
      );
      _registerLiveLocationListeners(
        onLocationSnapshot: onLocationSnapshot,
        onLocationUpdate: onLocationUpdate,
        onLocationRemove: onLocationRemove,
      );
      _registerPresenceListener(onPresenceUpdated);
      _socket!.off('connect_error');
      _socket!.on('connect_error', (error) {
        _log('connect_error=$error');
        if (onConnectError != null) onConnectError(error);
      });
      if (!(_socket?.connected ?? false)) {
        _log('existing socket not connected -> connect()');
        _socket?.connect();
      }
      return;
    }

    _socket = io.io(
      AppConfig.apiBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth(<String, dynamic>{
            if (authToken != null && authToken.trim().isNotEmpty)
              'token': authToken.trim(),
          })
          .setExtraHeaders(<String, dynamic>{
            ...?authHeaders,
            if (authToken != null && authToken.trim().isNotEmpty)
              'Authorization': 'Bearer ${authToken.trim()}',
          })
          .disableAutoConnect()
          .enableReconnection()
          .build(),
    );

    if (onNewMessage != null) {
      _socket!.on('newMessage', (data) {
        if (data is Map) {
          onNewMessage(
            ChannelMessageModel.fromJson(Map<String, dynamic>.from(data)),
          );
        }
      });
    }
    _registerFriendRequestListener(onFriendRequestReceived);
    _registerSocialEventListener(
      eventName: 'friendRequestSent',
      onEvent: onFriendRequestSent,
    );
    _registerSocialEventListener(
      eventName: 'friendRequestResponded',
      onEvent: onFriendRequestResponded,
    );
    _registerSocialEventListener(
      eventName: 'friendRequestCancelled',
      onEvent: onFriendRequestCancelled,
    );
    _registerSocialEventListener(
      eventName: 'friendshipBlocked',
      onEvent: onFriendshipBlocked,
    );
    _registerSocialEventListener(
      eventName: 'friendshipUnblocked',
      onEvent: onFriendshipUnblocked,
    );
    _registerSocialEventListener(
      eventName: 'friendshipDeleted',
      onEvent: onFriendshipDeleted,
    );
    _registerSocialEventListener(
      eventName: 'friendsStateUpdated',
      onEvent: onFriendsStateUpdated,
    );
    _registerSocialEventListener(
      eventName: 'channelInvited',
      onEvent: onChannelInvited,
    );
    _registerSocialEventListener(
      eventName: 'channelMemberRemoved',
      onEvent: onChannelMemberRemoved,
    );
    _registerSocialEventListener(
      eventName: 'userProfileUpdated',
      onEvent: onUserProfileUpdated,
    );

    _registerMessageErrorListener(onMessageError);
    _registerLiveLocationListeners(
      onLocationSnapshot: onLocationSnapshot,
      onLocationUpdate: onLocationUpdate,
      onLocationRemove: onLocationRemove,
    );
    _registerPresenceListener(onPresenceUpdated);
    _socket!.on('connect', (_) => requestLiveLocationsSnapshot());
    _socket!.on('reconnect', (_) => requestLiveLocationsSnapshot());
    _socket!.on('connect', (_) {
      _log('connected id=${_socket?.id}');
    });
    _socket!.on('disconnect', (reason) {
      _log('disconnected reason=$reason');
    });
    _socket!.on('connect_error', (error) {
      _log('connect_error=$error');
      if (onConnectError != null) onConnectError(error);
    });
    _socket!.on('reconnect', (_) {
      _log('reconnected id=${_socket?.id}');
    });

    _socket!.connect();
  }

  void _registerPresenceListener(
    void Function(Map<String, dynamic> payload)? onPresenceUpdated,
  ) {
    if (_socket == null) return;
    _socket!.off('presenceUpdated');
    _socket!.on('presenceUpdated', (data) {
      if (onPresenceUpdated == null || data is! Map) return;
      onPresenceUpdated(Map<String, dynamic>.from(data));
    });
  }

  void _registerFriendRequestListener(
    void Function(Map<String, dynamic> payload)? onFriendRequestReceived,
  ) {
    if (_socket == null) return;
    _socket!.off('friendRequestReceived');
    _socket!.on('friendRequestReceived', (data) {
      _log('event friendRequestReceived payload=$data');
      if (onFriendRequestReceived == null || data is! Map) return;
      onFriendRequestReceived(Map<String, dynamic>.from(data));
    });
  }

  void _registerSocialEventListener({
    required String eventName,
    void Function(Map<String, dynamic> payload)? onEvent,
  }) {
    if (_socket == null) return;
    _socket!.off(eventName);
    _socket!.on(eventName, (data) {
      _log('event $eventName payload=$data');
      if (onEvent == null || data is! Map) return;
      onEvent(Map<String, dynamic>.from(data));
    });
  }

  void joinChannel({required int channelId, required int userId}) {
    _socket?.emit('joinChannel', {'channelId': channelId, 'userId': userId});
  }

  void leaveChannel({required int channelId, required int userId}) {
    _socket?.emit('leaveChannel', {'channelId': channelId, 'userId': userId});
  }

  void sendPrivateMessage({
    required int senderId,
    required String content,
    required int channelId,
  }) {
    _socket?.emit('privateMessage', {
      'senderId': senderId,
      'content': content,
      'channelId': channelId,
    });
  }

  void requestLiveLocationsSnapshot() {
    _socket?.emit('location:sync');
  }

  void publishLiveLocation({
    required int userId,
    required String username,
    String? avatar,
    required double latitude,
    required double longitude,
    double? accuracy,
  }) {
    _socket?.emit('location:update', {
      'userId': userId,
      'username': username,
      'avatar': avatar,
      'lat': latitude,
      'lng': longitude,
      'accuracy': accuracy,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  void stopLiveLocationSharing({required int userId}) {
    _socket?.emit('location:stop', {'userId': userId});
  }

  void _registerLiveLocationListeners({
    void Function(List<dynamic> payload)? onLocationSnapshot,
    void Function(Map<String, dynamic> payload)? onLocationUpdate,
    void Function(int userId)? onLocationRemove,
  }) {
    if (_socket == null) return;

    for (final eventName in _eventLocationSnapshotCandidates) {
      _socket!.off(eventName);
      _socket!.on(eventName, (data) {
        if (onLocationSnapshot == null) return;
        if (data is List) {
          onLocationSnapshot(List<dynamic>.from(data));
          return;
        }
        if (data is Map && data['users'] is List) {
          onLocationSnapshot(List<dynamic>.from(data['users'] as List));
        }
      });
    }

    for (final eventName in _eventLocationUpdateCandidates) {
      _socket!.off(eventName);
      _socket!.on(eventName, (data) {
        if (onLocationUpdate == null || data is! Map) return;
        onLocationUpdate(Map<String, dynamic>.from(data));
      });
    }

    for (final eventName in _eventLocationRemoveCandidates) {
      _socket!.off(eventName);
      _socket!.on(eventName, (data) {
        if (onLocationRemove == null) return;
        if (data is int) {
          onLocationRemove(data);
          return;
        }
        if (data is num) {
          onLocationRemove(data.toInt());
          return;
        }
        if (data is String) {
          final parsed = int.tryParse(data);
          if (parsed != null) onLocationRemove(parsed);
          return;
        }
        if (data is Map) {
          final map = Map<String, dynamic>.from(data);
          final raw = map['userId'] ?? map['user_id'] ?? map['id'];
          if (raw is int) {
            onLocationRemove(raw);
            return;
          }
          if (raw is num) {
            onLocationRemove(raw.toInt());
            return;
          }
          if (raw is String) {
            final parsed = int.tryParse(raw);
            if (parsed != null) onLocationRemove(parsed);
          }
        }
      });
    }
  }

  void _registerMessageErrorListener(
    void Function(String message)? onMessageError,
  ) {
    if (_socket == null) return;
    _socket!.off('messageError');
    _socket!.on('messageError', (data) {
      if (onMessageError == null) return;
      final message = _coerceMessageError(data);
      if (message.isEmpty) return;
      onMessageError(message);
    });
  }

  String _coerceMessageError(dynamic data) {
    if (data is String) return data.trim();
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final message = map['message'] ?? map['error'] ?? map['detail'];
      if (message is String) return message.trim();
      if (message is List) return message.join('\n').trim();
      return data.toString().trim();
    }
    return data?.toString().trim() ?? '';
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}
