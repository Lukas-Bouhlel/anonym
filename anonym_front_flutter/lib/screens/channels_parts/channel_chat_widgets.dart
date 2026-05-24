part of '../channels_screen.dart';

class _ChatDetailView extends StatefulWidget {
  const _ChatDetailView({
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserAvatarUrl,
    required this.currentUserFrameUrl,
    required this.isDm,
    this.dmPeerName,
    this.dmPeerAvatarUrl,
    this.dmPeerPresenceStatus,
    this.dmPeerPresenceLabel,
    this.onDmHeaderTap,
    required this.messageController,
    required this.editingMessage,
    required this.onCancelEdit,
    required this.onBack,
    required this.onSendText,
    required this.onSendImage,
    required this.onInfo,
    required this.onEdit,
    required this.onDelete,
    required this.selected,
    required this.messages,
    required this.loading,
    required this.showGroupMenu,
  });

  final int? currentUserId;
  final String? currentUserName;
  final String? currentUserAvatarUrl;
  final String? currentUserFrameUrl;
  final bool isDm;
  final String? dmPeerName;
  final String? dmPeerAvatarUrl;
  final String? dmPeerPresenceStatus;
  final String? dmPeerPresenceLabel;
  final VoidCallback? onDmHeaderTap;
  final TextEditingController messageController;
  final ChannelMessageModel? editingMessage;
  final VoidCallback onCancelEdit;
  final VoidCallback onBack;
  final VoidCallback onSendText;

  /// Appelé avec (filePath, bytes, fileName, textContent).
  /// Sur mobile : filePath est renseigné ; sur web : bytes est renseigné.
  final Future<void> Function(
    String? filePath,
    Uint8List? bytes,
    String? fileName,
    String textContent,
  )
  onSendImage;

  final VoidCallback onInfo;
  final ValueChanged<ChannelMessageModel> onEdit;
  final ValueChanged<ChannelMessageModel> onDelete;
  final ChannelModel selected;
  final List<ChannelMessageModel> messages;
  final bool loading;
  final bool showGroupMenu;

  @override
  State<_ChatDetailView> createState() => _ChatDetailViewState();
}

class _ChatDetailViewState extends State<_ChatDetailView> {
  final ScrollController _scrollController = ScrollController();
  bool _shouldScrollToBottom = true;
  int? _lastChannelId;
  int? _lastMessageId;

  // Image sélectionnée en attente d'envoi
  String? _pendingImagePath;
  Uint8List? _pendingImageBytes;
  String? _pendingImageFileName;

  bool _isSendingImage = false;

  Future<void> _pickImage() async {
    final result = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (result == null) return;

    if (kIsWeb) {
      final bytes = await result.readAsBytes();
      setState(() {
        _pendingImageBytes = bytes;
        _pendingImagePath = null;
        _pendingImageFileName = result.name;
      });
    } else {
      setState(() {
        _pendingImagePath = result.path;
        _pendingImageBytes = null;
        _pendingImageFileName = result.name;
      });
    }
  }

  void _clearPendingImage() {
    setState(() {
      _pendingImagePath = null;
      _pendingImageBytes = null;
      _pendingImageFileName = null;
    });
  }

  bool get _hasPendingImage =>
      _pendingImagePath != null || _pendingImageBytes != null;

  void _scrollToBottom() {
    if (widget.messages.isEmpty || !_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    final target = position.maxScrollExtent;
    if (target <= 0) {
      return;
    }

    if (_scrollController.offset != target) {
      _scrollController.jumpTo(target);
    }
  }

  void _scheduleScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_scrollController.hasClients || widget.messages.isEmpty) {
        Future<void>.delayed(const Duration(milliseconds: 50), () {
          if (!mounted) return;
          _scheduleScrollToBottom();
        });
        return;
      }

      if (_scrollController.position.maxScrollExtent <= 0) {
        Future<void>.delayed(const Duration(milliseconds: 50), () {
          if (!mounted) return;
          _scheduleScrollToBottom();
        });
        return;
      }

      _scrollToBottom();
      _shouldScrollToBottom = false;
    });
  }

  void _maybeScrollToBottom() {
    final currentChannelId = widget.selected.channelId;
    final currentMessageId = widget.messages.isNotEmpty
        ? widget.messages.last.messageId
        : null;

    if (_lastChannelId != currentChannelId ||
        _lastMessageId != currentMessageId) {
      _lastChannelId = currentChannelId;
      _lastMessageId = currentMessageId;
      _shouldScrollToBottom = true;
      _scheduleScrollToBottom();
    }
  }

  Future<void> _handleSend() async {
    if (_hasPendingImage) {
      setState(() => _isSendingImage = true);
      try {
        await widget.onSendImage(
          _pendingImagePath,
          _pendingImageBytes,
          _pendingImageFileName,
          widget.messageController.text.trim(),
        );
        widget.messageController.clear();
        _clearPendingImage();
      } finally {
        if (mounted) setState(() => _isSendingImage = false);
      }
    } else {
      widget.onSendText();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scheduleScrollToBottom();
  }

  @override
  void didUpdateWidget(covariant _ChatDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected.channelId != oldWidget.selected.channelId ||
        widget.messages.length != oldWidget.messages.length ||
        (widget.messages.isNotEmpty &&
            oldWidget.messages.isNotEmpty &&
            widget.messages.last.messageId !=
                oldWidget.messages.last.messageId)) {
      _shouldScrollToBottom = true;
    }
    if (_shouldScrollToBottom) {
      _scheduleScrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    _maybeScrollToBottom();
    final headerTitle =
        widget.isDm &&
            widget.dmPeerName != null &&
            widget.dmPeerName!.trim().isNotEmpty
        ? widget.dmPeerName!.trim()
        : widget.selected.name;
    final headerAvatarUrl = widget.isDm
        ? widget.dmPeerAvatarUrl
        : widget.selected.coverImage;

    return SafeArea(
      maintainBottomViewPadding: true,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                MojiBackButton(onTap: widget.onBack),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: widget.isDm
                        ? widget.onDmHeaderTap
                        : (widget.showGroupMenu ? widget.onInfo : null),
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: widget.isDm
                              ? Stack(
                                  children: [
                                    ClipOval(
                                      child: AppRemoteImage(
                                        url: headerAvatarUrl,
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                        fallbackIcon: Icons.person,
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: PresenceBadge(
                                        presenceStatus:
                                            widget.dmPeerPresenceStatus ??
                                            PresenceUtils.offline,
                                        isCurrentUser: false,
                                        size: 11,
                                        borderColor: AppColors.cFCFAFE,
                                      ),
                                    ),
                                  ],
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.cFCFAFE.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.cFCFAFE.withValues(
                                        alpha: 0.20,
                                      ),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: AppRemoteImage(
                                      url: headerAvatarUrl,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                      fallbackIcon: Icons.alternate_email,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                headerTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.cFCFAFE,
                                  fontFamily: AppTypography.displayFontFamily,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.showGroupMenu)
                  _HeaderIcon(icon: Icons.more_vert, onTap: widget.onInfo),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.cFCFAFE.withValues(alpha: 0.22)),
          if (widget.loading) const LinearProgressIndicator(minHeight: 2),

          // ── Messages list ────────────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(
                      14,
                      18,
                      14,
                      100 +
                          MediaQuery.of(context).viewPadding.bottom +
                          (widget.editingMessage != null ? 60 : 0),
                    ),
                    itemCount: widget.messages.length,
                    itemBuilder: (context, index) {
                      final message = widget.messages[index];
                      final previous = index > 0
                          ? widget.messages[index - 1]
                          : null;
                      final messageSenderId =
                          (message.sender?.id != 0
                              ? message.sender?.id
                              : null) ??
                          message.senderId;
                      final previousSenderId =
                          (previous?.sender?.id != 0
                              ? previous?.sender?.id
                              : null) ??
                          previous?.senderId;
                      final sameDay =
                          previous?.createdAt != null &&
                          message.createdAt != null &&
                          previous!.createdAt!.year ==
                              message.createdAt!.year &&
                          previous.createdAt!.month ==
                              message.createdAt!.month &&
                          previous.createdAt!.day == message.createdAt!.day;
                      final own = messageSenderId == widget.currentUserId;
                      final next = index + 1 < widget.messages.length
                          ? widget.messages[index + 1]
                          : null;
                      final msgHour = message.createdAt == null
                          ? null
                          : DateTime(
                              message.createdAt!.year,
                              message.createdAt!.month,
                              message.createdAt!.day,
                              message.createdAt!.hour,
                            );
                      final prevHour = previous?.createdAt == null
                          ? null
                          : DateTime(
                              previous!.createdAt!.year,
                              previous.createdAt!.month,
                              previous.createdAt!.day,
                              previous.createdAt!.hour,
                            );
                      final nextHour = next?.createdAt == null
                          ? null
                          : DateTime(
                              next!.createdAt!.year,
                              next.createdAt!.month,
                              next.createdAt!.day,
                              next.createdAt!.hour,
                            );
                      final nextSenderId =
                          (next?.sender?.id != 0 ? next?.sender?.id : null) ??
                          next?.senderId;
                      final sameSenderAsPrevious =
                          previous != null &&
                          previousSenderId == messageSenderId &&
                          prevHour == msgHour;
                      final sameSenderAsNext =
                          next != null &&
                          nextSenderId == messageSenderId &&
                          nextHour == msgHour;
                      final isLastInSenderBlock = !sameSenderAsNext;
                      final showAuthorBlock = !own && !sameSenderAsPrevious;
                      final showOwnAuthorBlock = own && !sameSenderAsPrevious;
                      final senderName =
                          (message.sender?.username ?? '').trim().isNotEmpty
                          ? message.sender!.username
                          : 'User #${messageSenderId ?? '?'}';
                      final now = DateTime.now();
                      final isToday =
                          message.createdAt != null &&
                          message.createdAt!.year == now.year &&
                          message.createdAt!.month == now.month &&
                          message.createdAt!.day == now.day;
                      final separatorLabel = isToday
                          ? "Aujourd'hui"
                          : AppDateFormat.shortDate(message.createdAt);
                      final blockFooterLabel = isToday
                          ? AppDateFormat.shortTime(message.createdAt)
                          : '${AppDateFormat.shortDate(message.createdAt)} ${AppDateFormat.shortTime(message.createdAt)}';

                      return Column(
                        crossAxisAlignment: own
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (!sameDay && message.createdAt != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: AppColors.cFCFAFE.withValues(
                                        alpha: 0.55,
                                      ),
                                      height: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      separatorLabel,
                                      style: const TextStyle(
                                        color: AppColors.cFCFAFE,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: AppColors.cFCFAFE.withValues(
                                        alpha: 0.55,
                                      ),
                                      height: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          _MessageBubble(
                            own: own,
                            message: message,
                            showAuthorBlock: showAuthorBlock,
                            showOwnAuthorBlock: showOwnAuthorBlock,
                            senderName: senderName,
                            ownName:
                                (widget.currentUserName ?? '').trim().isNotEmpty
                                ? widget.currentUserName!
                                : 'Moi',
                            senderAvatarUrl: message.sender?.avatar,
                            ownAvatarUrl: widget.currentUserAvatarUrl,
                            senderFrameUrl: _activeFrameUrlFromUser(
                              message.sender,
                            ),
                            ownFrameUrl: widget.currentUserFrameUrl,
                            showBlockFooter: isLastInSenderBlock,
                            blockFooterLabel: blockFooterLabel,
                            onAvatarTap:
                                !own &&
                                    message.sender != null &&
                                    message.sender!.id > 0
                                ? () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(28),
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      builder: (_) => FractionallySizedBox(
                                        heightFactor: 0.86,
                                        child: UserProfileScreen(
                                          user: message.sender!,
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            onEdit: own ? () => widget.onEdit(message) : null,
                            onDelete: own
                                ? () => widget.onDelete(message)
                                : null,
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // ── Input bar (fixed bottom) ─────────────────────────────
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.editingMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              gradient: AppGradients.gB1BCFBTo393566,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppColors.cFCFAFE.withValues(
                                  alpha: 0.18,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: widget.onCancelEdit,
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: AppColors.cFCFAFE.withValues(
                                        alpha: 0.10,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: AppColors.cFCFAFE,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Modification du message',
                                    style: const TextStyle(
                                      color: AppColors.cFCFAFE,
                                      fontFamily:
                                          AppTypography.displayFontFamily,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // ── Image preview ────────────────────────────────
                        if (_hasPendingImage)
                          _ImagePreviewBar(
                            imagePath: _pendingImagePath,
                            imageBytes: _pendingImageBytes,
                            onRemove: _clearPendingImage,
                          ),
                        if (_hasPendingImage) const SizedBox(height: 6),

                        // ── Text + send ──────────────────────────────────
                        Container(
                          constraints: const BoxConstraints(
                            minHeight: 52,
                            maxHeight: 180,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppGradients.gB1BCFBTo393566,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _GradientSquareIcon(
                                icon: Icons.add,
                                onTap: _isSendingImage ? () {} : _pickImage,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: TextField(
                                  controller: widget.messageController,
                                  keyboardType: TextInputType.multiline,
                                  textInputAction: TextInputAction.newline,
                                  minLines: 1,
                                  maxLines: 5,
                                  textAlignVertical: TextAlignVertical.center,
                                  onSubmitted: (_) => _handleSend(),
                                  cursorColor: AppColors.whiteColor,
                                  style: const TextStyle(
                                    color: AppColors.whiteColor,
                                    fontSize: 15,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: _hasPendingImage
                                        ? 'Ajouter un message...'
                                        : 'Envoyez un message...',
                                    hintStyle: TextStyle(
                                      color: AppColors.cFCFAFE.withValues(
                                        alpha: 0.68,
                                      ),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w100,
                                    ),
                                    filled: false,
                                    fillColor: Colors.transparent,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 10,
                                    ),
                                    isCollapsed: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              _isSendingImage
                                  ? const SizedBox(
                                      width: 42,
                                      height: 42,
                                      child: Center(
                                        child: SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.cFCFAFE,
                                          ),
                                        ),
                                      ),
                                    )
                                  : _GradientSquareIcon(
                                      svgAsset: 'assets/icons/mouse.svg',
                                      onTap: _handleSend,
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _activeFrameUrlFromUser(UserModel? user) {
    if (user == null) return null;
    for (final item in user.inventories) {
      if (!item.active) continue;
      final shop = item.shop;
      if (shop == null) continue;
      if (shop.type.trim().toUpperCase() != 'CADRE') continue;
      final content = shop.content.trim();
      if (content.isNotEmpty) return content;
    }
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Preview bar : miniature + bouton supprimer
// ─────────────────────────────────────────────────────────────────────────────

class _ImagePreviewBar extends StatelessWidget {
  const _ImagePreviewBar({
    required this.imagePath,
    required this.imageBytes,
    required this.onRemove,
  });

  final String? imagePath;
  final Uint8List? imageBytes;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (imageBytes != null) {
      imageWidget = Image.memory(
        imageBytes!,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
      );
    } else if (imagePath != null) {
      imageWidget = Image.file(
        File(imagePath!),
        width: 72,
        height: 72,
        fit: BoxFit.cover,
      );
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: AppGradients.gB1BCFBTo393566,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cFCFAFE.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageWidget,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Image sélectionnée',
              style: TextStyle(
                color: AppColors.cFCFAFE.withValues(alpha: 0.85),
                fontSize: 14,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.cFCFAFE.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.cFCFAFE,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bulle de message (text + image optionnel)
// ─────────────────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.own,
    required this.message,
    required this.showAuthorBlock,
    required this.showOwnAuthorBlock,
    required this.senderName,
    required this.ownName,
    required this.showBlockFooter,
    required this.blockFooterLabel,
    this.senderAvatarUrl,
    this.ownAvatarUrl,
    this.senderFrameUrl,
    this.ownFrameUrl,
    this.onEdit,
    this.onDelete,
    this.onAvatarTap,
  });

  final bool own;
  final ChannelMessageModel message;
  final bool showAuthorBlock;
  final bool showOwnAuthorBlock;
  final String senderName;
  final String ownName;
  final bool showBlockFooter;
  final String blockFooterLabel;
  final String? senderAvatarUrl;
  final String? ownAvatarUrl;
  final String? senderFrameUrl;
  final String? ownFrameUrl;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: Radius.circular(own ? 0 : 14),
      bottomRight: Radius.circular(own ? 14 : 0),
    );
    final startsBlock = own ? showOwnAuthorBlock : showAuthorBlock;
    final showIdentityOnThisMessage = own ? startsBlock : true;
    final avatarUrl = own ? ownAvatarUrl : senderAvatarUrl;
    final frameUrl = own ? ownFrameUrl : senderFrameUrl;
    final displayName = own ? ownName : senderName;

    final hasImage = message.imageUrl != null && message.imageUrl!.isNotEmpty;
    final hasText = message.content.trim().isNotEmpty;
    final sharedProfilePayload = hasText
        ? ProfileSharePayloadCodec.tryDecode(message.content)
        : null;
    final hasSharedProfile = sharedProfilePayload != null;

    Future<void> openSharedProfile(ProfileSharePayload payload) async {
      final app = context.read<AppController>();
      UserModel? sharedUser;
      for (final user in app.allUsers) {
        if (user.id == payload.userId) {
          sharedUser = user;
          break;
        }
      }
      sharedUser ??= UserModel(
        id: payload.userId,
        username: payload.username,
        email: '',
      );

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
        builder: (_) => FractionallySizedBox(
          heightFactor: 0.86,
          child: UserProfileScreen(user: sharedUser!),
        ),
      );
    }

    final avatar = showIdentityOnThisMessage
        ? GestureDetector(
            onTap: (!own) ? onAvatarTap : null,
            child: _ChatMessageAvatar(avatarUrl: avatarUrl, frameUrl: frameUrl),
          )
        : const SizedBox(width: 52, height: 52);

    final messageColumn = Flexible(
      child: Column(
        crossAxisAlignment: own
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          if (showIdentityOnThisMessage) ...[
            Transform.translate(
              offset: const Offset(0, 8),
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 8),
                child: Text(
                  displayName,
                  style: const TextStyle(
                    color: AppColors.cFCFAFE,
                    fontFamily: AppTypography.displayFontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w100,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: hasImage && !hasText ? 0 : 14,
                vertical: hasImage && !hasText ? 0 : 14,
              ),
              decoration: BoxDecoration(
                color: hasImage && !hasText
                    ? Colors.transparent
                    : (own ? AppColors.primary : AppColors.whiteColor),
                borderRadius: bubbleRadius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image
                  if (hasImage)
                    ClipRRect(
                      borderRadius: hasText
                          ? const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                            )
                          : bubbleRadius,
                      child: AppRemoteImage(
                        url: message.imageUrl,
                        width: 240,
                        height: 200,
                        fit: BoxFit.cover,
                        fallbackIcon: Icons.broken_image_outlined,
                      ),
                    ),
                  // Texte
                  if (hasText) ...[
                    if (hasImage) const SizedBox(height: 8),
                    Padding(
                      padding: hasImage
                          ? const EdgeInsets.fromLTRB(14, 0, 14, 14)
                          : EdgeInsets.zero,
                      child: hasSharedProfile
                          ? _SharedProfileMessageCard(
                              own: own,
                              payload: sharedProfilePayload,
                              onTap: () =>
                                  openSharedProfile(sharedProfilePayload),
                            )
                          : Text(
                              message.content,
                              style: TextStyle(
                                color: own
                                    ? AppColors.whiteColor
                                    : AppColors.textPrimary,
                                fontSize: 15,
                                fontFamily: AppTypography.displayFontFamily,
                                height: 1.35,
                              ),
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (showBlockFooter) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (own) ...[
                  const _MessageStatusCheck(),
                  const SizedBox(width: 8),
                ],
                Text(
                  blockFooterLabel,
                  style: TextStyle(
                    color: AppColors.cFCFAFE.withValues(alpha: 0.68),
                    fontFamily: AppTypography.displayFontFamily,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    Future<void> showMessageOptions() async {
      if (onEdit == null && onDelete == null) return;

      final selectedAction = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            decoration: const BoxDecoration(
              gradient: AppGradients.gB1BCFBTo393566,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.cFCFAFE.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (onEdit != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          gradient: AppGradients.gB1BCFBTo393566,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.cFCFAFE.withValues(alpha: 0.12),
                          ),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.edit,
                            color: AppColors.cFCFAFE,
                          ),
                          title: const Text(
                            'Modifier le message',
                            style: TextStyle(color: AppColors.cFCFAFE),
                          ),
                          onTap: () => Navigator.of(context).pop('edit'),
                        ),
                      ),
                    if (onDelete != null)
                      Container(
                        decoration: BoxDecoration(
                          gradient: AppGradients.gB1BCFBTo393566,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.cFCFAFE.withValues(alpha: 0.12),
                          ),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.delete_outline,
                            color: AppColors.danger,
                          ),
                          title: const Text(
                            'Supprimer le message',
                            style: TextStyle(color: AppColors.danger),
                          ),
                          onTap: () => Navigator.of(context).pop('delete'),
                        ),
                      ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          );
        },
      );

      if (selectedAction == 'edit') {
        onEdit?.call();
      } else if (selectedAction == 'delete') {
        onDelete?.call();
      }
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: showBlockFooter ? 18 : 8,
        left: own ? 0 : 42,
        right: own ? 42 : 0,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: own ? showMessageOptions : null,
        child: Row(
          mainAxisAlignment: own
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: own ? [avatar, messageColumn] : [messageColumn, avatar],
        ),
      ),
    );
  }
}

// ─── Widgets inchangés ────────────────────────────────────────────────────────

class _SharedProfileMessageCard extends StatelessWidget {
  const _SharedProfileMessageCard({
    required this.own,
    required this.payload,
    required this.onTap,
  });

  final bool own;
  final ProfileSharePayload payload;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = own ? AppColors.whiteColor : AppColors.textPrimary;
    final subtleColor = own
        ? AppColors.whiteColor.withValues(alpha: 0.82)
        : AppColors.textPrimary.withValues(alpha: 0.78);
    final outlineColor = own
        ? AppColors.whiteColor.withValues(alpha: 0.20)
        : AppColors.c393566.withValues(alpha: 0.18);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: outlineColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_pin_circle_outlined, color: textColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Compte partage',
                    style: TextStyle(
                      color: subtleColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    payload.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: textColor, size: 22),
          ],
        ),
      ),
    );
  }
}

class _ChatMessageAvatar extends StatelessWidget {
  const _ChatMessageAvatar({required this.avatarUrl, required this.frameUrl});

  final String? avatarUrl;
  final String? frameUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.c393566,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.cFCFAFE.withValues(alpha: 0.18),
              ),
            ),
            child: ClipOval(
              child: AppRemoteImage(
                url: avatarUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                fallbackIcon: Icons.alternate_email,
              ),
            ),
          ),
          if (frameUrl != null)
            IgnorePointer(
              child: AppRemoteImage(
                url: frameUrl,
                width: 52,
                height: 52,
                fit: BoxFit.contain,
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageStatusCheck extends StatelessWidget {
  const _MessageStatusCheck();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        gradient: AppGradients.gB1BCFBTo393566,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_rounded,
        color: AppColors.whiteColor,
        size: 17,
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Ink(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.whiteColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.whiteColor.withValues(alpha: 0.12),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.c121212.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.cFCFAFE),
          ),
        ),
      ),
    );
  }
}

class _GradientSquareIcon extends StatelessWidget {
  const _GradientSquareIcon({required this.onTap, this.icon, this.svgAsset})
    : assert(icon != null || svgAsset != null);

  final IconData? icon;
  final String? svgAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 42.38,
        height: 42.38,
        decoration: BoxDecoration(
          gradient: svgAsset == null
              ? LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.cB1BCFB.withValues(alpha: 0.20),
                    AppColors.c393566.withValues(alpha: 0.20),
                  ],
                )
              : AppGradients.gB1BCFBTo393566,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: svgAsset == null
              ? Icon(icon, color: AppColors.cFCFAFE, size: 21.18)
              : SvgPicture.asset(
                  svgAsset!,
                  width: 21.18,
                  height: 21.18,
                  colorFilter: const ColorFilter.mode(
                    AppColors.cFCFAFE,
                    BlendMode.srcIn,
                  ),
                ),
        ),
      ),
    );
  }
}
