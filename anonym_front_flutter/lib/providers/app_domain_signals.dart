import 'package:flutter/foundation.dart';

/// Domain-level listenables used to avoid rebuilding every feature slice
/// when unrelated state changes in [AppProvider].
class AppDomainSignals {
  final ValueNotifier<int> _orchestrator = ValueNotifier<int>(0);
  final ValueNotifier<int> _social = ValueNotifier<int>(0);
  final ValueNotifier<int> _channels = ValueNotifier<int>(0);
  final ValueNotifier<int> _commerce = ValueNotifier<int>(0);
  final ValueNotifier<int> _presence = ValueNotifier<int>(0);
  final ValueNotifier<int> _notifications = ValueNotifier<int>(0);

  Listenable get orchestrator => _orchestrator;
  Listenable get social => _social;
  Listenable get channels => _channels;
  Listenable get commerce => _commerce;
  Listenable get presence => _presence;
  Listenable get notifications => _notifications;

  void bumpOrchestrator() => _orchestrator.value++;
  void bumpSocial() => _social.value++;
  void bumpChannels() => _channels.value++;
  void bumpCommerce() => _commerce.value++;
  void bumpPresence() => _presence.value++;
  void bumpNotifications() => _notifications.value++;

  void dispose() {
    _orchestrator.dispose();
    _social.dispose();
    _channels.dispose();
    _commerce.dispose();
    _presence.dispose();
    _notifications.dispose();
  }
}
