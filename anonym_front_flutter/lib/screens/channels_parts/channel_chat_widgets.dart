part of '../channels_screen.dart';

class _ChatDetailView extends StatelessWidget {
  const _ChatDetailView({
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserAvatarUrl,
    required this.currentUserFrameUrl,
    required this.messageController,
    required this.onBack,
    required this.onSend,
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
  final TextEditingController messageController;
  final VoidCallback onBack;
  final VoidCallback onSend;
  final VoidCallback onInfo;
  final ValueChanged<ChannelMessageModel> onEdit;
  final ValueChanged<ChannelMessageModel> onDelete;
  final ChannelModel selected;
  final List<ChannelMessageModel> messages;
  final bool loading;
  final bool showGroupMenu;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                MojiBackButton(onTap: onBack),
                const SizedBox(width: 10),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.cFCFAFE.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.cFCFAFE.withValues(alpha: 0.20),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AppRemoteImage(
                      url: selected.coverImage,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      fallbackIcon: Icons.alternate_email,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selected.name,
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
                if (showGroupMenu)
                  _HeaderIcon(icon: Icons.more_vert, onTap: onInfo),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.cFCFAFE.withValues(alpha: 0.22)),
          if (loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 18, 14, 190),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final previous = index > 0 ? messages[index - 1] : null;
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
                      final own = messageSenderId == currentUserId;
                      final next = index + 1 < messages.length
                          ? messages[index + 1]
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
                            ownName: (currentUserName ?? '').trim().isNotEmpty
                                ? currentUserName!
                                : 'Moi',
                            senderAvatarUrl: message.sender?.avatar,
                            ownAvatarUrl: currentUserAvatarUrl,
                            senderFrameUrl: _activeFrameUrlFromUser(
                              message.sender,
                            ),
                            ownFrameUrl: currentUserFrameUrl,
                            showBlockFooter: isLastInSenderBlock,
                            blockFooterLabel: blockFooterLabel,
                            onEdit: own ? () => onEdit(message) : null,
                            onDelete: own ? () => onDelete(message) : null,
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 20),
                    child: Container(
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
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _GradientSquareIcon(icon: Icons.add, onTap: () {}),
                          const SizedBox(width: 5),
                          Expanded(
                            child: TextField(
                              controller: messageController,
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                              minLines: 1,
                              maxLines: 5,
                              textAlignVertical: TextAlignVertical.bottom,
                              onSubmitted: (_) => onSend(),
                              cursorColor: AppColors.whiteColor,
                              style: const TextStyle(
                                color: AppColors.whiteColor,
                                fontSize: 15,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Envoyez un message...',
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
                                  vertical: 14,
                                ),
                                isCollapsed: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _GradientSquareIcon(
                            svgAsset: 'assets/icons/mouse.svg',
                            onTap: onSend,
                          ),
                        ],
                      ),
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

  @override
  Widget build(BuildContext context) {
    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: Radius.circular(own ? 0 : 14),
      bottomRight: Radius.circular(own ? 14 : 0),
    );
    final startsBlock = own ? showOwnAuthorBlock : showAuthorBlock;
    final avatarUrl = own ? ownAvatarUrl : senderAvatarUrl;
    final frameUrl = own ? ownFrameUrl : senderFrameUrl;
    final displayName = own ? ownName : senderName;

    final avatar = startsBlock
        ? _ChatMessageAvatar(avatarUrl: avatarUrl, frameUrl: frameUrl)
        : const SizedBox(width: 52, height: 52);

    final messageColumn = Flexible(
      child: Column(
        crossAxisAlignment: own
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          if (startsBlock) ...[
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: own ? AppColors.primary : AppColors.whiteColor,
                borderRadius: bubbleRadius,
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: own ? AppColors.whiteColor : AppColors.textPrimary,
                  fontSize: 15,
                  fontFamily: AppTypography.displayFontFamily,
                  height: 1.35,
                ),
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

    return Padding(
      padding: EdgeInsets.only(
        bottom: showBlockFooter ? 18 : 8,
        left: own ? 0 : 42,
        right: own ? 42 : 0,
      ),
      child: Row(
        mainAxisAlignment: own
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: own ? [avatar, messageColumn] : [messageColumn, avatar],
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
