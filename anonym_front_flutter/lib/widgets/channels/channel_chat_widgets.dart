part of '../../screens/channels_screen.dart';

class _ChatDetailView extends StatefulWidget {
  const _ChatDetailView({
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserAvatarUrl,
    required this.currentUserFrameUrl,
    required this.isDm,
    this.dmPeerName,
    this.dmPeerAvatarUrl,
    this.dmPeerFrameUrl,
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
  final String? dmPeerFrameUrl;
  final String? dmPeerPresenceStatus;
  final String? dmPeerPresenceLabel;
  final VoidCallback? onDmHeaderTap;
  final TextEditingController messageController;
  final ChannelMessageModel? editingMessage;
  final VoidCallback onCancelEdit;
  final VoidCallback onBack;
  final VoidCallback onSendText;

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
    final app = context.read<AppProvider>();
    final headerTitle =
        widget.isDm &&
            widget.dmPeerName != null &&
            widget.dmPeerName!.trim().isNotEmpty
        ? widget.dmPeerName!.trim()
        : widget.selected.name;
    final headerAvatarUrl = widget.isDm
        ? widget.dmPeerAvatarUrl
        : widget.selected.coverImage;
    final headerDmFrameUrl =
        widget.isDm && (widget.dmPeerFrameUrl?.trim().isNotEmpty ?? false)
        ? widget.dmPeerFrameUrl
        : null;

    return SafeArea(
      maintainBottomViewPadding: true,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnonymBackButton(onTap: widget.onBack),
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
                                    Stack(
                                      alignment: Alignment.center,
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
                                        if (headerDmFrameUrl != null)
                                          IgnorePointer(
                                            child: AppRemoteImage(
                                              url: headerDmFrameUrl,
                                              width: 48,
                                              height: 48,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                      ],
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
                  _HeaderIcon(
                    icon: Icons.more_vert,
                    onTap: widget.onInfo,
                    semanticsLabel: 'Options de la conversation',
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.cFCFAFE.withValues(alpha: 0.22)),
          if (widget.loading) const LinearProgressIndicator(minHeight: 2),

          // Messages list
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

                      UserModel? resolvedSenderForFrame;
                      if (messageSenderId != null && messageSenderId > 0) {
                        for (final member in app.channelMembers) {
                          if (member.id == messageSenderId) {
                            resolvedSenderForFrame = member;
                            break;
                          }
                        }
                        resolvedSenderForFrame ??= app.userById(
                          messageSenderId,
                        );
                      }
                      resolvedSenderForFrame ??= message.sender;

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
                              resolvedSenderForFrame,
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

                // Input bar (fixed bottom)
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
                                Semantics(
                                  button: true,
                                  label: 'Annuler la modification du message',
                                  child: GestureDetector(
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
                                      child: const ExcludeSemantics(
                                        child: Icon(
                                          Icons.close_rounded,
                                          color: AppColors.cFCFAFE,
                                          size: 20,
                                        ),
                                      ),
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
                        // Image preview
                        if (_hasPendingImage)
                          _ImagePreviewBar(
                            imagePath: _pendingImagePath,
                            imageBytes: _pendingImageBytes,
                            onRemove: _clearPendingImage,
                          ),
                        if (_hasPendingImage) const SizedBox(height: 6),

                        // Text + send
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
                                semanticsLabel: 'Ajouter une image',
                                onTap: _isSendingImage ? () {} : _pickImage,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Semantics(
                                  textField: true,
                                  label: 'Message',
                                  hint: _hasPendingImage
                                      ? 'Ajoute un texte avec l image'
                                      : 'Ecris un message',
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
                                      labelText: 'Message',
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.never,
                                      labelStyle: const TextStyle(
                                        fontSize: 0,
                                        height: 0,
                                      ),
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
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 10,
                                          ),
                                      isCollapsed: true,
                                    ),
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
                                      semanticsLabel: 'Envoyer le message',
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
    if (user == null || user.id <= 0) return null;
    for (final item in user.inventories) {
      if (!item.active) continue;
      if (item.userId > 0 && item.userId != user.id) continue;
      final shop = item.shop;
      if (shop == null) continue;
      final content = shop.content.trim();
      if (content.isEmpty) continue;
      final type = shop.type.trim().toUpperCase();
      if (type == 'CADRE') return content;
    }
    return null;
  }
}
