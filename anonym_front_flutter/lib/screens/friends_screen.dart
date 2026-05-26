import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/friend_model.dart';
import '../models/user_model.dart';
import '../providers/app_providers.dart';
import '../screens/notifications_screen.dart';
import '../screens/user_profile_screen.dart';
import '../theme.dart';
import '../widgets/app_remote_image.dart';
import '../widgets/presence_badge.dart';


part '../widgets/friends_screen_widgets.dart';

/// Écran social: amis, demandes et découverte de profils.
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
    return Consumer<AppProvider>(
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
          color: AppColors.whiteColor,
          backgroundColor: AppColors.primary,
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

  Widget _buildAddMode(AppProvider app, List<UserModel> discoverableUsers) {
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
              'Aucun utilisateur trouvé.',
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
    AppProvider app,
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
          _SectionHeader(title: 'Demandes reçues', count: incoming.length),
          const SizedBox(height: 8),
          if (incoming.isEmpty)
            const _EmptySectionText('Aucune demande reçue.')
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
          _SectionHeader(title: 'Demandes envoyées', count: outgoing.length),
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
    final app = context.read<AppProvider>();
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
    AppProvider app,
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
    final app = context.read<AppProvider>();
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
    AppProvider app, {
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
    final app = context.read<AppProvider>();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return _FriendSheetShell(
          title: 'Actions amis',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choisis une action pour gérer tes relations rapidement.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.cFCFAFE, fontSize: 13),
              ),
              const SizedBox(height: 14),
              _FriendActionRow(
                icon: Icons.groups_rounded,
                label: 'Voir mes amis',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  setState(() => _mode = _FriendScreenMode.list);
                },
              ),
              const SizedBox(height: 8),
              _FriendActionRow(
                icon: Icons.person_add_alt_1_rounded,
                label: 'Ajouter un ami',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  setState(() => _mode = _FriendScreenMode.add);
                  unawaited(app.refreshUsers(silent: true));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addFriend(
    AppProvider app,
    String value, {
    int? userId,
  }) async {
    final username = value.trim();
    if (username.isEmpty) return;
    if (app.isFriendRequestPending(userId: userId, username: username)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Demande déjà en attente.')));
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
      SnackBar(content: Text(isPending ? 'Demande envoyée' : 'Ami ajouté')),
    );
  }

  Future<void> _respondIncoming(
    AppProvider app,
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

  Future<void> _cancelOutgoing(AppProvider app, int requestId) async {
    await app.cancelOutgoingFriendRequest(requestId);
    if (!mounted || app.errorMessage == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(app.errorMessage!)));
  }
}
