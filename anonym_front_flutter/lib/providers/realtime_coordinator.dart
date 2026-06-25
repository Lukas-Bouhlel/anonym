import 'dart:async';

import '../services/api_client.dart';
import '../services/socket_service.dart';

/// Coordinates realtime socket lifecycle, keepalive, and auth recovery.
class RealtimeCoordinator {
  RealtimeCoordinator({
    required ApiClient apiClient,
    required SocketService socketService,
    required bool Function() isLoggedIn,
    required bool Function() isAppInForeground,
    required Future<void> Function() connectSocketWithLatestAuth,
    required void Function() scheduleSocialStateRefresh,
    required void Function(String message) log,
  }) : _apiClient = apiClient,
       _socketService = socketService,
       _isLoggedIn = isLoggedIn,
       _isAppInForeground = isAppInForeground,
       _connectSocketWithLatestAuth = connectSocketWithLatestAuth,
       _scheduleSocialStateRefresh = scheduleSocialStateRefresh,
       _log = log;

  final ApiClient _apiClient;
  final SocketService _socketService;
  final bool Function() _isLoggedIn;
  final bool Function() _isAppInForeground;
  final Future<void> Function() _connectSocketWithLatestAuth;
  final void Function() _scheduleSocialStateRefresh;
  final void Function(String message) _log;

  Timer? _sessionKeepAliveTimer;
  bool _isRecoveringSocketSession = false;
  DateTime? _lastSocketRecoveryAt;

  void startSessionKeepAlive() {
    _sessionKeepAliveTimer?.cancel();
    _sessionKeepAliveTimer = Timer.periodic(const Duration(minutes: 8), (_) {
      unawaited(performSessionKeepAliveTick());
    });
  }

  void stopSessionKeepAlive() {
    _sessionKeepAliveTimer?.cancel();
    _sessionKeepAliveTimer = null;
  }

  Future<void> performSessionKeepAliveTick() async {
    if (!_isLoggedIn()) return;
    if (!_isAppInForeground()) return;
    try {
      final refreshed = await _apiClient.refreshSession();
      _log('session keepalive refreshed=$refreshed');
      if (!refreshed) return;
      if (_socketService.isConnected) return;
      await recoverSocketSession(reason: 'keepalive_socket_disconnected');
    } catch (_) {
      // Best-effort keepalive; retry next tick.
    }
  }

  void onSocketConnectError(dynamic error) {
    final message = error?.toString() ?? '';
    _log('socket connect_error callback=$message');
    if (!_isSocketAuthError(message)) return;
    unawaited(recoverSocketSession(reason: 'socket_auth_error'));
  }

  Future<void> recoverSocketSession({required String reason}) async {
    if (_isRecoveringSocketSession) return;
    final now = DateTime.now();
    final last = _lastSocketRecoveryAt;
    if (last != null && now.difference(last) < const Duration(seconds: 10)) {
      return;
    }

    _isRecoveringSocketSession = true;
    _lastSocketRecoveryAt = now;
    _log('socket recover start reason=$reason');
    try {
      final refreshed = await _apiClient.refreshSession();
      _log('socket recover refreshSession=$refreshed');
      if (!refreshed) return;

      _socketService.disconnect();
      await _connectSocketWithLatestAuth();
      _scheduleSocialStateRefresh();
    } catch (error) {
      _log('socket recover failed error=$error');
    } finally {
      _isRecoveringSocketSession = false;
    }
  }

  void reset() {
    stopSessionKeepAlive();
    _isRecoveringSocketSession = false;
    _lastSocketRecoveryAt = null;
  }

  bool _isSocketAuthError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('auth') ||
        normalized.contains('jwt') ||
        normalized.contains('expired') ||
        normalized.contains('token');
  }
}
