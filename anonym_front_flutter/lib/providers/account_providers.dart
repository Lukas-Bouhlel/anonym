part of 'app_providers.dart';

/// Operations de compte: profil, presence, paiements et securite.
extension AppProviderAccountX on AppProvider {
  Future<String?> startCheckout(int articleId) {
    return _accountDomainService.startCheckout(articleId);
  }

  Future<PaymentConfirmationModel?> confirmPayment(String sessionId) {
    return _accountDomainService.confirmPayment(sessionId);
  }

  Future<void> activateInventoryItem(int itemId, bool active) {
    return _accountDomainService.activateInventoryItem(itemId, active);
  }

  Future<String?> sendInvoiceByEmail(int invoiceId) {
    return _accountDomainService.sendInvoiceByEmail(invoiceId);
  }

  Future<void> updateProfile({
    required String username,
    required String email,
    String? bio,
    bool? allowNonFriendDms,
    String? avatarFilePath,
    Uint8List? avatarBytes,
    String? avatarFileName,
    bool deleteAvatar = false,
  }) {
    return _accountDomainService.updateProfile(
      username: username,
      email: email,
      bio: bio,
      allowNonFriendDms: allowNonFriendDms,
      avatarFilePath: avatarFilePath,
      avatarBytes: avatarBytes,
      avatarFileName: avatarFileName,
      deleteAvatar: deleteAvatar,
    );
  }

  Future<void> updateMyPresenceStatus(String presenceStatus) {
    return _accountDomainService.updateMyPresenceStatus(presenceStatus);
  }

  Future<bool> openChannelById(int channelId) {
    return _accountDomainService.openChannelById(channelId);
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) {
    return _accountDomainService.updatePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmNewPassword: confirmNewPassword,
    );
  }

  Future<void> deleteAccount() {
    return _accountDomainService.deleteAccount();
  }

  void clearError() {
    _accountDomainService.clearError();
  }

  void clearMessageError() {
    _accountDomainService.clearMessageError();
  }

  void markAllNotificationsAsRead() {
    _accountDomainService.markAllNotificationsAsRead();
  }
}
