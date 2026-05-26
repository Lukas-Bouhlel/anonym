part of '../screens/friends_screen.dart';

enum _FriendScreenMode { list, add }

enum _FriendListFilter { friends, incoming, outgoing }

UserModel _resolveUserForAvatar(AppProvider app, UserModel fallback) {
  for (final candidate in app.allUsers) {
    if (candidate.id != fallback.id) continue;
    return fallback.copyWith(
      username: fallback.username.trim().isNotEmpty
          ? fallback.username
          : candidate.username,
      email: fallback.email.trim().isNotEmpty
          ? fallback.email
          : candidate.email,
      level: fallback.level > 0 ? fallback.level : candidate.level,
      createdAt: fallback.createdAt ?? candidate.createdAt,
      avatar: (fallback.avatar?.trim().isNotEmpty ?? false)
          ? fallback.avatar
          : candidate.avatar,
      bio: (fallback.bio?.trim().isNotEmpty ?? false)
          ? fallback.bio
          : candidate.bio,
      roles: fallback.roles ?? candidate.roles,
      presenceStatus: fallback.presenceStatus ?? candidate.presenceStatus,
      inventories: candidate.inventories.isNotEmpty
          ? candidate.inventories
          : fallback.inventories,
    );
  }
  return fallback;
}

String? _activeFrameUrlForUser(AppProvider app, UserModel user) {
  String? fallbackContent;
  for (final item in user.inventories) {
    if (!item.active) continue;
    final fromInventory = item.shop;
    if (fromInventory != null) {
      final content = fromInventory.content.trim();
      if (content.isNotEmpty) {
        final itemType = fromInventory.type.trim().toUpperCase();
        if (itemType == 'CADRE') return content;
        fallbackContent ??= content;
      }
    }
    for (final shopItem in app.shopItems) {
      if (shopItem.articleId != item.articleId) continue;
      final content = shopItem.content.trim();
      if (content.isEmpty) continue;
      if (shopItem.type.trim().toUpperCase() == 'CADRE') return content;
      fallbackContent ??= content;
    }
  }
  return fallbackContent;
}

class _UserAvatarWithDecoration extends StatelessWidget {
  const _UserAvatarWithDecoration({
    required this.app,
    required this.user,
    required this.size,
    required this.badgeSize,
    required this.fallbackIcon,
  });

  final AppProvider app;
  final UserModel user;
  final double size;
  final double badgeSize;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final frameUrl = _activeFrameUrlForUser(app, user);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipOval(
                child: AppRemoteImage(
                  url: user.avatar,
                  width: size,
                  height: size,
                  fallbackIcon: fallbackIcon,
                ),
              ),
              if (frameUrl != null)
                IgnorePointer(
                  child: AppRemoteImage(
                    url: frameUrl,
                    width: size + 4,
                    height: size + 4,
                    fit: BoxFit.contain,
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: PresenceBadge(
            presenceStatus: app.presenceStatusForUser(user.id),
            isCurrentUser: false,
            size: badgeSize,
            borderColor: AppColors.cFCFAFE,
          ),
        ),
      ],
    );
  }
}

class _ListFilterBar extends StatelessWidget {
  const _ListFilterBar({
    required this.selected,
    required this.friendsCount,
    required this.incomingCount,
    required this.outgoingCount,
    required this.onSelected,
  });

  final _FriendListFilter selected;
  final int friendsCount;
  final int incomingCount;
  final int outgoingCount;
  final ValueChanged<_FriendListFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ListFilterChip(
            label: 'Amis',
            count: friendsCount,
            isActive: selected == _FriendListFilter.friends,
            onTap: () => onSelected(_FriendListFilter.friends),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ListFilterChip(
            label: 'Recues',
            count: incomingCount,
            isActive: selected == _FriendListFilter.incoming,
            onTap: () => onSelected(_FriendListFilter.incoming),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ListFilterChip(
            label: 'Envoyees',
            count: outgoingCount,
            isActive: selected == _FriendListFilter.outgoing,
            onTap: () => onSelected(_FriendListFilter.outgoing),
          ),
        ),
      ],
    );
  }
}

class _ListFilterChip extends StatelessWidget {
  const _ListFilterChip({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            gradient: isActive ? AppGradients.gB1BCFBTo393566 : null,
            color: isActive ? null : AppColors.cB1BCFB.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.whiteColor.withValues(
                alpha: isActive ? 0.35 : 0.24,
              ),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.whiteColor.withValues(
                      alpha: isActive ? 1 : 0.9,
                    ),
                    fontFamily: AppTypography.primaryFontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.whiteColor.withValues(
                    alpha: isActive ? 0.2 : 0.14,
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: AppColors.whiteColor,
                    fontFamily: AppTypography.primaryFontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.cDBE7FE,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 7),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(
            color: AppColors.cB1BCFB.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: AppColors.cFCFAFE,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptySectionText extends StatelessWidget {
  const _EmptySectionText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.cDBE7FE, fontSize: 14),
      ),
    );
  }
}

class _AddFriendInfoCard extends StatelessWidget {
  const _AddFriendInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cB1BCFB.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.cFCFAFE.withValues(alpha: 0.28),
          width: 1,
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.person_search_rounded,
              color: AppColors.cFCFAFE,
              size: 18,
            ),
          ),
          SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ajouter un ami',
                  style: TextStyle(
                    color: AppColors.cFCFAFE,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  "Recherche un pseudo pour envoyer une demande d'ami.",
                  style: TextStyle(
                    color: AppColors.cDBE7FE,
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendSheetShell extends StatelessWidget {
  const _FriendSheetShell({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          10,
          16,
          16 + mediaQuery.padding.bottom,
        ),
        decoration: BoxDecoration(
          gradient: AppGradients.gB1BCFBTo393566,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.cFCFAFE.withValues(alpha: 0.28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.cFCFAFE.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppTypography.displayFontFamily,
                  color: AppColors.cFCFAFE,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendActionRow extends StatelessWidget {
  const _FriendActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.cFCFAFE.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cFCFAFE.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.cFCFAFE, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.cFCFAFE,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.cDBE7FE),
          ],
        ),
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({required this.friend, required this.app});

  final FriendModel friend;
  final AppProvider app;

  @override
  Widget build(BuildContext context) {
    final details = friend.friendDetails;
    final user =
        details ??
        UserModel(id: friend.friendId, username: 'Utilisateur', email: '');
    final displayUser = _resolveUserForAvatar(app, user);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              clipBehavior: Clip.antiAlias,
              builder: (_) => FractionallySizedBox(
                heightFactor: 0.86,
                child: UserProfileScreen(user: displayUser),
              ),
            );
          },
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.cB1BCFB.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.cFCFAFE.withValues(alpha: 0.48),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                _UserAvatarWithDecoration(
                  app: app,
                  user: displayUser,
                  size: 43,
                  badgeSize: 11,
                  fallbackIcon: Icons.person_outline_rounded,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayUser.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.cFCFAFE,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await app.deleteFriend(friend.friendId);
                    if (!context.mounted || app.errorMessage == null) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(app.errorMessage!)));
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.cFCFAFE,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IncomingRequestTile extends StatelessWidget {
  const _IncomingRequestTile({
    required this.request,
    required this.app,
    required this.onAccept,
    required this.onBlock,
  });

  final FriendModel request;
  final AppProvider app;
  final VoidCallback onAccept;
  final VoidCallback onBlock;

  @override
  Widget build(BuildContext context) {
    final details = request.friendDetails;
    final user = details ?? _resolveIncomingRequestUser(app, request);
    final displayUser = _resolveUserForAvatar(app, user);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              clipBehavior: Clip.antiAlias,
              builder: (_) => FractionallySizedBox(
                heightFactor: 0.86,
                child: UserProfileScreen(user: displayUser),
              ),
            );
          },
          child: Container(
            height: 76,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.cB1BCFB.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.cFCFAFE.withValues(alpha: 0.48),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                _UserAvatarWithDecoration(
                  app: app,
                  user: displayUser,
                  size: 43,
                  badgeSize: 11,
                  fallbackIcon: Icons.person_outline_rounded,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayUser.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.cFCFAFE,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Accepter',
                  onPressed: onAccept,
                  icon: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                  ),
                ),
                IconButton(
                  tooltip: 'Refuser',
                  onPressed: onBlock,
                  icon: const Icon(
                    Icons.cancel_rounded,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  UserModel _resolveIncomingRequestUser(
    AppProvider app,
    FriendModel request,
  ) {
    for (final candidate in app.allUsers) {
      if (candidate.id == request.userId) {
        return candidate;
      }
    }
    return UserModel(id: request.userId, username: 'Utilisateur', email: '');
  }
}

class _OutgoingRequestTile extends StatelessWidget {
  const _OutgoingRequestTile({
    required this.request,
    required this.app,
    required this.onCancel,
  });

  final FriendModel request;
  final AppProvider app;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final details = request.friendDetails;
    final user =
        details ??
        UserModel(id: request.friendId, username: 'Utilisateur', email: '');
    final displayUser = _resolveUserForAvatar(app, user);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              clipBehavior: Clip.antiAlias,
              builder: (_) => FractionallySizedBox(
                heightFactor: 0.86,
                child: UserProfileScreen(user: displayUser),
              ),
            );
          },
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.cB1BCFB.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.cFCFAFE.withValues(alpha: 0.48),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                _UserAvatarWithDecoration(
                  app: app,
                  user: displayUser,
                  size: 43,
                  badgeSize: 11,
                  fallbackIcon: Icons.person_outline_rounded,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayUser.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.cFCFAFE,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'En attente',
                        style: TextStyle(
                          color: AppColors.cDBE7FE,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Annuler',
                  onPressed: onCancel,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.cFCFAFE,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscoverableUserTile extends StatelessWidget {
  const _DiscoverableUserTile({
    required this.user,
    required this.app,
    required this.onTap,
    required this.onAdd,
  });

  final UserModel user;
  final AppProvider app;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: app.hydrateUserDetails(user.id),
      builder: (context, snapshot) {
        final hydrated = snapshot.data;
        final displayUser = _resolveUserForAvatar(app, hydrated ?? user);
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.cB1BCFB.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.cFCFAFE.withValues(alpha: 0.36),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  _UserAvatarWithDecoration(
                    app: app,
                    user: displayUser,
                    size: 41,
                    badgeSize: 11,
                    fallbackIcon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      displayUser.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.cFCFAFE,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onAdd,
                    icon: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: AppColors.cFCFAFE,
                      size: 22,
                    ),
                    tooltip: 'Envoyer une demande',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
