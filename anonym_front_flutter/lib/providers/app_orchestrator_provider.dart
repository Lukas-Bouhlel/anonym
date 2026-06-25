import 'package:flutter/foundation.dart';

import 'app_providers.dart';

/// Lightweight orchestrator exposed to UI for app-wide refresh/error/loading.
class AppOrchestratorProvider extends ChangeNotifier {
  AppOrchestratorProvider(this._app) {
    _listener = notifyListeners;
    _app.orchestratorListenable.addListener(_listener);
  }

  final AppProvider _app;
  late final VoidCallback _listener;

  bool get isBootstrapping => _app.isBootstrapping;
  bool get isSubmitting => _app.isSubmitting;
  String? get errorMessage => _app.errorMessage;

  Future<void> refreshAll() => _app.refreshAll();

  void clearError() => _app.clearError();

  @override
  void dispose() {
    _app.orchestratorListenable.removeListener(_listener);
    super.dispose();
  }
}
