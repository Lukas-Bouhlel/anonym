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

  void connect({
    void Function(ChannelMessageModel message)? onNewMessage,
    void Function(String message)? onMessageError,
    void Function(List<dynamic> payload)? onLocationSnapshot,
    void Function(Map<String, dynamic> payload)? onLocationUpdate,
    void Function(int userId)? onLocationRemove,
  }) {
    if (_socket != null) {
      _registerMessageErrorListener(onMessageError);
      _registerLiveLocationListeners(
        onLocationSnapshot: onLocationSnapshot,
        onLocationUpdate: onLocationUpdate,
        onLocationRemove: onLocationRemove,
      );
      return;
    }

    _socket = io.io(
      AppConfig.apiBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
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

    _registerMessageErrorListener(onMessageError);
    _registerLiveLocationListeners(
      onLocationSnapshot: onLocationSnapshot,
      onLocationUpdate: onLocationUpdate,
      onLocationRemove: onLocationRemove,
    );
    _socket!.on('connect', (_) => requestLiveLocationsSnapshot());
    _socket!.on('reconnect', (_) => requestLiveLocationsSnapshot());

    _socket!.connect();
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
