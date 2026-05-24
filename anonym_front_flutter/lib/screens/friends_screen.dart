import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/friend_model.dart';
import '../models/user_model.dart';
import '../providers/app_controller.dart';
import '../screens/notifications_screen.dart';
import '../screens/user_profile_screen.dart';
import '../theme.dart';
import '../widgets/app_remote_image.dart';
import '../widgets/presence_badge.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  _FriendScreenMode _mode = _FriendScreenMode.list;
  _FriendListFilter _listFilter = _FriendListFilter.friends;
  bool _isLoadingInitialFriends = false;
  bool _isRealtimeSyncRunning = false;
  String _query = '';
  Timer? _realtimeSyncTimer;
  final Set<int> _hydratedDiscoverableUserIds = <int>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFriendsAtOpen();
      _startRealtimeSync();
    });
  }

  @override
  void dispose() {
    _realtimeSyncTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Consumer<AppController>(
      builder: (context, app, _) {
        final friends = app.friends
            .where((friend) => friend.status.trim().toUpperCase() == 'ACTIVE')
            .where(_matchesFriend)
            .toList(growable: false);
        final incoming = app.incomingFriendRequests
            .where((request) => _matchesRequest(request, app, isIncoming: true))
            .toList(growable: false);
        final outgoing = app.outgoingFriendRequests
            .where(
              (request) => _matchesRequest(request, app, isIncoming: false),
            )
            .toList(growable: false);
        final discoverableUsers = app.discoverableUsers
            .where(_matchesUserQuery)
            .toList(growable: false);

        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              app.refreshFriends(),
              app.refreshFriendRequests(),
              app.refreshUsers(silent: true),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 140),
            children: [
              SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Chercher', style: t.displayLarge),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                transitionDuration: const Duration(
                                  milliseconds: 260,
                                ),
                                reverseTransitionDuration: const Duration(
                                  milliseconds: 220,
                                ),
                                pageBuilder: (_, animation, _) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: const NotificationsScreen(),
                                  );
                                },
                                transitionsBuilder: (_, animation, _, child) {
                                  final slideAnimation =
                                      Tween<Offset>(
                                        begin: const Offset(1, 0),
                                        end: Offset.zero,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeOutCubic,
                                        ),
                                      );
                                  return SlideTransition(
                                    position: slideAnimation,
                                    child: child,
                                  );
                                },
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.notifications_none,
                            color: AppColors.whiteColor,
                            size: 27,
                          ),
                          style: IconButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(32, 32),
                          ),
                        ),
                        if (app.unreadNotificationsCount > 0)
                          Positioned(
                            right: -2,
                            top: -1,
                            child: Container(
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF4D2D),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppColors.c121212.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                app.unreadNotificationsCount > 99
                                    ? '99+'
                                    : '${app.unreadNotificationsCount}',
                                style: const TextStyle(
                                  color: AppColors.whiteColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 11.45),
                      decoration: BoxDecoration(
                        gradient: AppGradients.gB1BCFBTo393566,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            color: AppColors.whiteColor,
                            size: 27,
                          ),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) => setState(
                                () => _query = value.trim().toLowerCase(),
                              ),
                              style: const TextStyle(
                                color: AppColors.whiteColor,
                                fontFamily: AppTypography.primaryFontFamily,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                              cursorColor: AppColors.whiteColor,
                              decoration: InputDecoration(
                                hintText: _mode == _FriendScreenMode.add
                                    ? 'Rechercher un pseudo'
                                    : 'Chercher un ami',
                                hintStyle: const TextStyle(
                                  color: AppColors.whiteColor,
                                  fontFamily: AppTypography.primaryFontFamily,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                                filled: false,
                                fillColor: Colors.transparent,
                                isCollapsed: true,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.cB1BCFB.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: IconButton(
                      onPressed: () => _showModeModal(context),
                      icon: const Icon(
                        Icons.tune_rounded,
                        color: AppColors.cFCFAFE,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_mode == _FriendScreenMode.list) ...[
                _ListFilterBar(
                  selected: _listFilter,
                  friendsCount: friends.length,
                  incomingCount: incoming.length,
                  outgoingCount: outgoing.length,
                  onSelected: (value) => setState(() => _listFilter = value),
                ),
                const SizedBox(height: 14),
              ],
              if (_mode == _FriendScreenMode.add)
                _buildAddMode(app, discoverableUsers)
              else
                _buildListMode(app, friends, incoming, outgoing),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddMode(AppController app, List<UserModel> discoverableUsers) {
    _prefetchDiscoverableUsersDetails(app, discoverableUsers);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AddFriendInfoCard(),
        const SizedBox(height: 12),
        const Text(
          'Utilisateurs Anonym',
          style: TextStyle(
            color: AppColors.cDBE7FE,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (_query.isNotEmpty && discoverableUsers.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              'Aucun utilisateur trouve.',
              style: TextStyle(color: AppColors.cDBE7FE, fontSize: 14),
            ),
          )
        else
          ...discoverableUsers.map(
            (user) => _DiscoverableUserTile(
              user: user,
              app: app,
              onTap: () {
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
                    child: UserProfileScreen(user: user),
                  ),
                );
              },
              onAdd: () => _addFriend(app, user.username, userId: user.id),
            ),
          ),
      ],
    );
  }

  Widget _buildListMode(
    AppController app,
    List<FriendModel> friends,
    List<FriendModel> incoming,
    List<FriendModel> outgoing,
  ) {
    final showIncoming = _listFilter == _FriendListFilter.incoming;
    final showOutgoing = _listFilter == _FriendListFilter.outgoing;
    final showFriends = _listFilter == _FriendListFilter.friends;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isLoadingInitialFriends &&
            app.friends.isEmpty &&
            app.incomingFriendRequests.isEmpty &&
            app.outgoingFriendRequests.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.whiteColor.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Chargement...',
                  style: TextStyle(color: AppColors.cDBE7FE, fontSize: 15),
                ),
              ],
            ),
          ),
        if (showIncoming) ...[
          _SectionHeader(title: 'Demandes recues', count: incoming.length),
          const SizedBox(height: 8),
          if (incoming.isEmpty)
            const _EmptySectionText('Aucune demande recue.')
          else
            ...incoming.map(
              (request) => _IncomingRequestTile(
                request: request,
                app: app,
                onAccept: () => _respondIncoming(app, request.id, 'ACCEPTED'),
                onBlock: () => _respondIncoming(app, request.id, 'DECLINED'),
              ),
            ),
        ],
        if (showOutgoing) ...[
          _SectionHeader(title: 'Demandes envoyees', count: outgoing.length),
          const SizedBox(height: 8),
          if (outgoing.isEmpty)
            const _EmptySectionText('Aucune demande en attente.')
          else
            ...outgoing.map(
              (request) => _OutgoingRequestTile(
                request: request,
                app: app,
                onCancel: () => _cancelOutgoing(app, request.id),
              ),
            ),
        ],
        if (showFriends) ...[
          _SectionHeader(title: 'Amis', count: friends.length),
          const SizedBox(height: 8),
          if (friends.isEmpty)
            const _EmptySectionText('Aucun ami actif.')
          else
            ...friends.map((friend) => _FriendTile(friend: friend, app: app)),
        ],
      ],
    );
  }

  Future<void> _loadFriendsAtOpen() async {
    final app = context.read<AppController>();
    setState(() => _isLoadingInitialFriends = true);
    await Future.wait([
      if (app.friends.isEmpty) app.refreshFriends(silent: true),
      if (app.incomingFriendRequests.isEmpty &&
          app.outgoingFriendRequests.isEmpty)
        app.refreshFriendRequests(silent: true),
      if (app.allUsers.isEmpty) app.refreshUsers(silent: true),
    ]);
    if (!mounted) return;
    setState(() => _isLoadingInitialFriends = false);
  }

  void _prefetchDiscoverableUsersDetails(
    AppController app,
    List<UserModel> discoverableUsers,
  ) {
    if (discoverableUsers.isEmpty) return;
    final idsToHydrate = <int>[];
    for (final user in discoverableUsers.take(12)) {
      if (user.id <= 0) continue;
      if (_hydratedDiscoverableUserIds.contains(user.id)) continue;
      _hydratedDiscoverableUserIds.add(user.id);
      idsToHydrate.add(user.id);
    }
    if (idsToHydrate.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final userId in idsToHydrate) {
        unawaited(app.hydrateUserDetails(userId));
      }
    });
  }

  void _startRealtimeSync() {
    _realtimeSyncTimer?.cancel();
    _realtimeSyncTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      unawaited(_runRealtimeSyncTick());
    });
  }

  Future<void> _runRealtimeSyncTick() async {
    if (!mounted || _isRealtimeSyncRunning) return;
    final app = context.read<AppController>();
    if (app.isBootstrapping) return;
    if (app.isSocketConnected) return;

    _isRealtimeSyncRunning = true;
    try {
      await Future.wait([
        app.refreshFriendRequests(silent: true),
        app.refreshFriends(silent: true),
        if (_mode == _FriendScreenMode.add || _query.isNotEmpty)
          app.refreshUsers(silent: true),
      ]);
    } finally {
      _isRealtimeSyncRunning = false;
    }
  }

  bool _matchesFriend(FriendModel friend) {
    if (_query.isEmpty) return true;
    final username = friend.friendDetails?.username.toLowerCase() ?? '';
    return username.startsWith(_query);
  }

  bool _matchesRequest(
    FriendModel request,
    AppController app, {
    required bool isIncoming,
  }) {
    if (_query.isEmpty) return true;
    final targetId = isIncoming ? request.userId : request.friendId;
    final usernameFromRequest =
        request.friendDetails?.username.toLowerCase() ?? '';
    if (usernameFromRequest.startsWith(_query)) return true;
    UserModel? user;
    for (final candidate in app.allUsers) {
      if (candidate.id == targetId) {
        user = candidate;
        break;
      }
    }
    final username = user?.username.toLowerCase() ?? '';
    return username.startsWith(_query);
  }

  bool _matchesUserQuery(UserModel user) {
    if (_query.isEmpty) return false;
    return user.username.toLowerCase().startsWith(_query);
  }

  Future<void> _showModeModal(BuildContext context) async {
    final app = context.read<AppController>();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: Container(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 16),
            decoration: BoxDecoration(
              gradient: AppGradients.gB1BCFBTo393566,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(
                color: AppColors.whiteColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 74,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Actions amis',
                  style: TextStyle(
                    color: AppColors.whiteColor,
                    fontFamily: AppTypography.displayFontFamily,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: AppColors.whiteColor.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    children: [
                      _ModalActionTile(
                        title: 'Voir mes amis',
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          setState(() => _mode = _FriendScreenMode.list);
                        },
                      ),
                      const SizedBox(height: 10),
                      _ModalActionTile(
                        title: 'Ajouter un ami',
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          setState(() => _mode = _FriendScreenMode.add);
                          unawaited(app.refreshUsers(silent: true));
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addFriend(
    AppController app,
    String value, {
    int? userId,
  }) async {
    final username = value.trim();
    if (username.isEmpty) return;
    if (app.isFriendRequestPending(userId: userId, username: username)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Demande deja en attente.')));
      return;
    }
    final created = await app.addFriendByUsername(username, userId: userId);
    if (!mounted) return;
    if (app.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(app.errorMessage!)));
      return;
    }
    _searchController.text = username;
    setState(() => _query = username.toLowerCase());
    final isPending = created?.status.trim().toUpperCase() == 'PENDING';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isPending ? 'Demande envoyee' : 'Ami ajoute')),
    );
  }

  Future<void> _respondIncoming(
    AppController app,
    int requestId,
    String status,
  ) async {
    await app.respondToIncomingFriendRequest(
      requestId: requestId,
      status: status,
    );
    if (!mounted || app.errorMessage == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(app.errorMessage!)));
  }

  Future<void> _cancelOutgoing(AppController app, int requestId) async {
    await app.cancelOutgoingFriendRequest(requestId);
    if (!mounted || app.errorMessage == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(app.errorMessage!)));
  }
}

enum _FriendScreenMode { list, add }

enum _FriendListFilter { friends, incoming, outgoing }

UserModel _resolveUserForAvatar(AppController app, UserModel fallback) {
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

String? _activeFrameUrlForUser(AppController app, UserModel user) {
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

  final AppController app;
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

class _ModalActionTile extends StatelessWidget {
  const _ModalActionTile({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: AppColors.whiteColor.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.whiteColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppColors.whiteColor,
                  fontSize: 31 / 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.whiteColor,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({required this.friend, required this.app});

  final FriendModel friend;
  final AppController app;

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
  final AppController app;
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
    AppController app,
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
  final AppController app;
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
  final AppController app;
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
