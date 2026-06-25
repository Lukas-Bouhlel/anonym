class AppRuntimeStore {
  bool isBootstrapping = false;
  bool isLoadingMessages = false;
  bool isSubmitting = false;
  String? errorMessage;
  String? messageError;
  String? manualPresenceOverride;
  bool isAppInForeground = true;
  int realtimeStatsVersion = 0;
}
