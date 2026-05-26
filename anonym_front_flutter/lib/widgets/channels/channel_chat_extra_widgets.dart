part of '../../screens/channels_screen.dart';

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

// Bulle de message (text + image optionnel)
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
    final groupInvitePayload = hasText
        ? GroupInvitePayloadCodec.tryDecode(message.content)
        : null;
    final hasSharedProfile = sharedProfilePayload != null;
    final hasGroupInvite = groupInvitePayload != null;

    Future<void> openSharedProfile(ProfileSharePayload payload) async {
      final app = context.read<AppProvider>();
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
        avatar: payload.avatarUrl,
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

    Future<void> openGroupInvitePreview(GroupInvitePayload payload) async {
      final app = context.read<AppProvider>();
      final alreadyJoined = app.channels.any(
        (channel) => channel.channelId == payload.channelId,
      );
      final isPrivate =
          payload.channelVisibility.trim().toUpperCase() == 'PRIVATE';
      final subtitle = payload.channelDescription.trim().isEmpty
          ? (isPrivate
                ? "Le groupe a limité l'accès à ce profil."
                : 'Le groupe est visible dans les invitations.')
          : payload.channelDescription.trim();
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
        builder: (sheetContext) {
          return FractionallySizedBox(
            heightFactor: 0.48,
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppGradients.gB1BCFBTo393566,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.cFCFAFE.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Invitation de groupe',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.whiteColor,
                        fontFamily: AppTypography.displayFontFamily,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Divider(
                      height: 1,
                      color: AppColors.whiteColor.withValues(alpha: 0.2),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.cFCFAFE.withValues(
                                  alpha: 0.06,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppColors.cFCFAFE.withValues(
                                    alpha: 0.16,
                                  ),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _GroupInviteAvatar(
                                    coverImageUrl: payload.channelCoverImage,
                                    isPrivate: isPrivate,
                                    size: 56,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          payload.channelName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.cFCFAFE,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          subtitle,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: AppColors.cFCFAFE.withValues(
                                              alpha: 0.60,
                                            ),
                                            fontSize: 14,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton(
                                onPressed: () async {
                                  if (alreadyJoined) {
                                    Navigator.of(sheetContext).pop();
                                    await app.openChannelById(
                                      payload.channelId,
                                    );
                                    if (!context.mounted) return;
                                    final error = app.errorMessage;
                                    if (error != null && error.isNotEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(error)),
                                      );
                                    }
                                    return;
                                  }
                                  if (payload.inviteCode.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Invitation invalide.'),
                                      ),
                                    );
                                    return;
                                  }
                                  await app.joinByInviteCode(
                                    payload.inviteCode,
                                  );
                                  if (!context.mounted) return;
                                  final error = app.errorMessage;
                                  if (error != null && error.isNotEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(error)),
                                    );
                                    return;
                                  }
                                  Navigator.of(sheetContext).pop();
                                  await app.openChannelById(payload.channelId);
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.cFCFAFE.withValues(
                                    alpha: 0.16,
                                  ),
                                  foregroundColor: AppColors.cFCFAFE,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: AppColors.cFCFAFE.withValues(
                                        alpha: 0.30,
                                      ),
                                    ),
                                  ),
                                ),
                                child: Text(
                                  alreadyJoined
                                      ? 'Ouvrir le groupe'
                                      : 'Rejoindre le groupe',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
                          : hasGroupInvite
                          ? _GroupInviteMessageCard(
                              own: own,
                              payload: groupInvitePayload,
                              onTap: () =>
                                  openGroupInvitePreview(groupInvitePayload),
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

// Widgets inchangés
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
    final app = context.read<AppProvider>();
    final textColor = own ? AppColors.whiteColor : AppColors.textPrimary;
    final subtleColor = own
        ? AppColors.whiteColor.withValues(alpha: 0.82)
        : AppColors.textPrimary.withValues(alpha: 0.78);
    final outlineColor = own
        ? AppColors.whiteColor.withValues(alpha: 0.20)
        : AppColors.c393566.withValues(alpha: 0.18);
    return FutureBuilder<UserModel?>(
      future: app.hydrateUserDetails(payload.userId),
      builder: (context, snapshot) {
        final fallbackUser = app.userById(payload.userId);
        final resolvedUser = snapshot.data ?? fallbackUser;
        final resolvedAvatarUrl =
            (payload.avatarUrl?.trim().isNotEmpty ?? false)
            ? payload.avatarUrl
            : resolvedUser?.avatar;
        final resolvedFrameUrl = _activeFrameUrlFromUser(resolvedUser);

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
              mainAxisSize: MainAxisSize.max,
              children: [
                _ChatMessageAvatar(
                  avatarUrl: resolvedAvatarUrl,
                  frameUrl: resolvedFrameUrl,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Compte partagé',
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
      },
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

class _GroupInviteMessageCard extends StatelessWidget {
  const _GroupInviteMessageCard({
    required this.own,
    required this.payload,
    required this.onTap,
  });

  final bool own;
  final GroupInvitePayload payload;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPrivate =
        payload.channelVisibility.trim().toUpperCase() == 'PRIVATE';
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
          mainAxisSize: MainAxisSize.max,
          children: [
            _GroupInviteAvatar(
              coverImageUrl: payload.channelCoverImage,
              isPrivate: isPrivate,
              size: 56,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Invitation de groupe',
                    style: TextStyle(
                      color: subtleColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    payload.channelName,
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

class _GroupInviteAvatar extends StatelessWidget {
  const _GroupInviteAvatar({
    required this.coverImageUrl,
    required this.isPrivate,
    this.size = 56,
  });

  final String? coverImageUrl;
  final bool isPrivate;
  final double size;

  @override
  Widget build(BuildContext context) {
    final badgeSize = size <= 52 ? 18.0 : 20.0;
    final iconSize = size <= 52 ? 11.0 : 12.0;
    final imageRadius = size <= 52 ? 12.0 : 14.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.c393566,
              borderRadius: BorderRadius.circular(imageRadius),
              border: Border.all(
                color: AppColors.cFCFAFE.withValues(alpha: 0.2),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: AppRemoteImage(
              url: coverImageUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              fallbackIcon: Icons.alternate_email_rounded,
            ),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: AppColors.c393566,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.cFCFAFE.withValues(alpha: 0.25),
                ),
              ),
              child: Icon(
                isPrivate ? Icons.lock_rounded : Icons.public_rounded,
                size: iconSize,
                color: AppColors.cFCFAFE,
              ),
            ),
          ),
        ],
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
        children: [
          Container(
            width: 52,
            height: 52,
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
