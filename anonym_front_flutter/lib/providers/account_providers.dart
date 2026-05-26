part of 'app_providers.dart';

/// Opérations de compte: profil, présence, paiements et sécurité.
extension AppProviderAccountX on AppProvider {
  Future<String?> startCheckout(int articleId) async {
    try {
      final url = await _paymentRepository.createCheckout(articleId);
      if (url.isEmpty) throw Exception('URL de paiement vide');
      return url;
    } catch (e) {
      _errorMessage = ApiErrorParser.parse(e, fallback: 'Paiement impossible');
      _notifyStateChanged();
      return null;
    }
  }

  Future<PaymentConfirmationModel?> confirmPayment(String sessionId) async {
    try {
      final confirmation = await _paymentRepository.confirm(sessionId);
      await Future.wait([
        refreshInventory(silent: true),
        refreshInvoices(silent: true),
        _refreshCurrentUser(),
      ]);
      _notifyStateChanged();
      return confirmation;
    } catch (e) {
      _errorMessage = ApiErrorParser.parse(
        e,
        fallback: 'Confirmation du paiement impossible',
      );
      _notifyStateChanged();
      return null;
    }
  }

  Future<void> activateInventoryItem(int itemId, bool active) async {
    await _wrap(() async {
      await _inventoryRepository.updateStatus(itemId: itemId, active: active);
      _inventoryItems = await _inventoryRepository.readAll();
      await _refreshCurrentUser();
    }, fallbackMessage: 'Activation impossible');
  }

  Future<String?> sendInvoiceByEmail(int invoiceId) async {
    try {
      return await _invoiceRepository.sendInvoiceByEmail(invoiceId);
    } catch (e) {
      _errorMessage = ApiErrorParser.parse(
        e,
        fallback: 'Envoi de la facture impossible',
      );
      _notifyStateChanged();
      return null;
    }
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
  }) async {
    await _wrap(() async {
      final updated = await _accountRepository.updateProfile(
        username: username,
        email: email,
        bio: bio,
        allowNonFriendDms: allowNonFriendDms,
        avatarFilePath: avatarFilePath,
        avatarBytes: avatarBytes,
        avatarFileName: avatarFileName,
        deleteAvatar: deleteAvatar,
      );
      _authProvider.setUser(updated);
    }, fallbackMessage: 'Mise à jour du profil impossible');
  }

  Future<void> updateMyPresenceStatus(String presenceStatus) async {
    await _wrap(() async {
      final normalized = PresenceUtils.normalize(presenceStatus);
      await _accountRepository.updatePresenceStatus(normalized);
      final me = _authProvider.user;
      if (me == null) return;
      _presenceByUserId[me.id] = normalized;
      if (normalized == PresenceUtils.dnd ||
          normalized == PresenceUtils.invisible) {
        _manualPresenceOverride = normalized;
      } else {
        _manualPresenceOverride = null;
      }
      _authProvider.setUser(me.copyWith(presenceStatus: normalized));
    }, fallbackMessage: 'Mise à jour du statut impossible');
  }

  Future<bool> openChannelById(int channelId) async {
    if (channelId <= 0) return false;
    ChannelModel? target;
    for (final channel in _channels) {
      if (channel.channelId == channelId) {
        target = channel;
        break;
      }
    }
    if (target == null) {
      await refreshChannels(silent: true);
      for (final channel in _channels) {
        if (channel.channelId == channelId) {
          target = channel;
          break;
        }
      }
    }
    if (target == null) {
      _errorMessage = 'Conversation introuvable.';
      _notifyStateChanged();
      return false;
    }
    await selectChannel(target);
    return _selectedChannel?.channelId == channelId;
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    await _wrap(() async {
      await _accountRepository.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmNewPassword: confirmNewPassword,
      );
    }, fallbackMessage: 'Mise à jour du mot de passe impossible');
  }

  Future<void> deleteAccount() async {
    await _wrap(() async {
      await _accountRepository.deleteAccount();
      await _authProvider.logout();
    }, fallbackMessage: 'Suppression du compte impossible');
  }

  void clearError() {
    _errorMessage = null;
    _notifyStateChanged();
  }

  void clearMessageError() {
    if (_messageError == null) return;
    _messageError = null;
    _notifyStateChanged();
  }

  void markAllNotificationsAsRead() {
    if (_notifications.isEmpty) return;
    var didChange = false;
    final nextReadIds = <String>{..._readNotificationIds};
    final next = _notifications
        .map((item) {
          nextReadIds.add(item.id);
          if (item.isRead) return item;
          didChange = true;
          return item.copyWith(isRead: true);
        })
        .toList(growable: false);
    if (!didChange && nextReadIds.length == _readNotificationIds.length) return;
    _notifications = next;
    _readNotificationIds = nextReadIds;
    _persistReadNotificationIds();
    _notifyStateChanged();
  }

}
