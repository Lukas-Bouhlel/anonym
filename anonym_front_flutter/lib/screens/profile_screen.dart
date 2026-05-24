import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/points_summary_model.dart';
import '../models/user_model.dart';
import '../providers/app_controller.dart';
import '../providers/auth_controller.dart';
import '../services/points_repository.dart';
import '../theme.dart';
import '../utils/presence_utils.dart';
import '../widgets/app_remote_image.dart';
import '../widgets/presence_badge.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<PointsSummaryModel> _pointsFuture;

  @override
  void initState() {
    super.initState();
    _pointsFuture = _loadPoints();
  }

  Future<PointsSummaryModel> _loadPoints() {
    return context.read<PointsRepository>().readMe();
  }

  Future<void> _reloadPoints() async {
    final future = _loadPoints();
    setState(() => _pointsFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;
    final isCurrentUser = user != null;
    final t = Theme.of(context).textTheme;

    return Consumer<AppController>(
      builder: (context, app, _) {
        final activeItem = app.inventoryItems
            .where((item) => item.active)
            .toList(growable: false);
        String activeDecoration = '';
        final myPresence = user == null
            ? PresenceUtils.offline
            : app.presenceStatusForUser(user.id, isCurrentUser: true);
        if (activeItem.isNotEmpty) {
          final firstActive = activeItem.first;
          final fromInventory = (firstActive.shop?.content ?? '').trim();
          if (fromInventory.isNotEmpty) {
            activeDecoration = fromInventory;
          } else {
            final fromShop = app.shopItems
                .where((shop) => shop.articleId == firstActive.articleId)
                .map((shop) => shop.content.trim())
                .firstWhere((url) => url.isNotEmpty, orElse: () => '');
            activeDecoration = fromShop;
          }
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              auth.reloadCurrentUser(),
              app.refreshInventory(),
              app.refreshInvoices(),
              _reloadPoints(),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 140),
            children: [
              SafeArea(
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppGradients.gB1BCFBTo393566,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppColors.cFCFAFE.withValues(alpha: 0.38),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 58,
                            height: 58,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipOval(
                                  child: AppRemoteImage(
                                    url: user?.avatar,
                                    width: 58,
                                    height: 58,
                                    fallbackIcon: Icons.person,
                                  ),
                                ),
                                if (activeDecoration.isNotEmpty)
                                  AppRemoteImage(
                                    url: activeDecoration,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.contain,
                                    fallbackIcon: Icons.blur_on_rounded,
                                  ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: InkWell(
                                    onTap: !isCurrentUser
                                        ? null
                                        : () => _showPresencePicker(
                                            context,
                                            app: app,
                                            currentStatus: myPresence,
                                          ),
                                    borderRadius: BorderRadius.circular(999),
                                    child: PresenceBadge(
                                      presenceStatus: myPresence,
                                      isCurrentUser: true,
                                      size: 18,
                                      borderColor: AppColors.cFCFAFE,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.username ?? '',
                                  style: t.displayMedium?.copyWith(height: 0.9),
                                ),
                                Text(
                                  (user?.bio ?? '').trim().isEmpty
                                      ? ''
                                      : user!.bio!,
                                  style: const TextStyle(
                                    color: AppColors.cDBE7FE,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            ),
                            icon: const Icon(
                              Icons.tune,
                              color: AppColors.cFCFAFE,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const EditProfileScreen(),
                                ),
                              ),
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: AppGradients.gB1BCFBTo393566,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: AppColors.cFCFAFE.withValues(
                                      alpha: 0.55,
                                    ),
                                    width: 1.4,
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Modifier le profil',
                                        style: TextStyle(
                                          color: AppColors.cFCFAFE,
                                          fontFamily:
                                              AppTypography.primaryFontFamily,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SvgPicture.asset(
                                        'assets/icons/edit_profil_icon.svg',
                                        width: 18,
                                        height: 18,
                                        colorFilter: const ColorFilter.mode(
                                          AppColors.cFCFAFE,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _showShareModal(
                              context,
                              userId: user?.id ?? 0,
                              username: user?.username ?? 'Utilisateur',
                              avatarUrl: user?.avatar,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: AppGradients.gB1BCFBTo393566,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(18),
                                ),
                                border: Border.all(
                                  color: AppColors.cFCFAFE.withValues(
                                    alpha: 0.55,
                                  ),
                                  width: 1.4,
                                ),
                              ),
                              child: Center(
                                child: SvgPicture.asset(
                                  'assets/icons/share.svg',
                                  width: 16,
                                  height: 16,
                                  colorFilter: const ColorFilter.mode(
                                    AppColors.cFCFAFE,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FutureBuilder<PointsSummaryModel>(
                future: _pointsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.cFCFAFE,
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cB1BCFB.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.cFCFAFE.withValues(alpha: 0.28),
                        ),
                      ),
                      child: const Text(
                        'Progression indisponible pour le moment.',
                        style: TextStyle(color: AppColors.cFCFAFE),
                      ),
                    );
                  }

                  final points = snapshot.data!;
                  final level = points.user.level;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Progression',
                            style: t.displaySmall?.copyWith(height: 0.9),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [AppColors.c9D5EDF, AppColors.cD0BAFF],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.whiteColor.withValues(
                                  alpha: 0.50,
                                ),
                              ),
                            ),
                            child: Text(
                              'LVL  ${level.level}',
                              style: const TextStyle(
                                fontFamily: AppTypography.displayFontFamily,
                                color: AppColors.cFCFAFE,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 64,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: AppColors.cFCFAFE.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.cFCFAFE.withValues(alpha: 0.34),
                          ),
                        ),
                        child: _LevelTimelineBar(level: level),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Réputation',
                        style: t.displaySmall?.copyWith(height: 0.9),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cB1BCFB.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.cFCFAFE.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.auto_awesome,
                                  color: AppColors.cCFFFDD,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Niveau ${level.level}',
                                  style: const TextStyle(
                                    color: AppColors.cFCFAFE,
                                    fontSize: 32,
                                    height: 0.9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${points.totals.pointsEarned} pts',
                                  style: const TextStyle(
                                    color: AppColors.cCFFFDD,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${points.totals.messagesCount} messages sur une periode de ${points.period == 'day'
                                  ? 'jours'
                                  : points.period == 'week'
                                  ? 'semaines'
                                  : points.period == 'month'
                                  ? 'mois'
                                  : ""}',
                              style: const TextStyle(color: AppColors.cDBE7FE),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              child: CustomPaint(
                                painter: _ReputationLinePainter(
                                  history: points.history,
                                ),
                                size: const Size(double.infinity, 120),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showShareModal(
    BuildContext context, {
    required int userId,
    required String username,
    String? avatarUrl,
  }) async {
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) =>
            ShareProfileScreen(
              userId: userId,
              username: username,
              avatarUrl: avatarUrl,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final offset =
              Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );
          return SlideTransition(position: offset, child: child);
        },
      ),
    );
  }

  Future<void> _showPresencePicker(
    BuildContext context, {
    required AppController app,
    required String currentStatus,
  }) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        Widget tile(String status) {
          return ListTile(
            leading: PresenceBadge(
              presenceStatus: status,
              isCurrentUser: true,
              size: 14,
            ),
            title: Text(
              PresenceUtils.label(status, isCurrentUser: true),
              style: const TextStyle(color: AppColors.cFCFAFE),
            ),
            trailing: currentStatus == status
                ? const Icon(Icons.check, color: AppColors.cCFFFDD)
                : null,
            onTap: () => Navigator.of(context).pop(status),
          );
        }

        return SafeArea(
          top: false,
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
                const Text(
                  'Changer le statut en ligne',
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
                const SizedBox(height: 8),
                tile(PresenceUtils.online),
                tile(PresenceUtils.idle),
                tile(PresenceUtils.dnd),
                tile(PresenceUtils.invisible),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
    if (selected == null || selected == currentStatus) return;
    await app.updateMyPresenceStatus(selected);
  }
}

class _LevelTimelineBar extends StatefulWidget {
  const _LevelTimelineBar({required this.level});

  final PointsLevelModel level;

  @override
  State<_LevelTimelineBar> createState() => _LevelTimelineBarState();
}

class _LevelTimelineBarState extends State<_LevelTimelineBar> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _focusLevelKey = GlobalKey();
  bool _didAutoScroll = false;

  @override
  void didUpdateWidget(covariant _LevelTimelineBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level.level != widget.level.level) {
      _didAutoScroll = false;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scrollToCurrentIfNeeded();

    final currentLevel = widget.level.level <= 0 ? 1 : widget.level.level;
    final lastVisibleLevel = (currentLevel + 3).clamp(
      currentLevel,
      widget.level.maxLevel,
    );

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            for (var level = 1; level <= lastVisibleLevel; level++) ...[
              _buildLevelNode(level, currentLevel),
              if (level < lastVisibleLevel)
                _buildLevelConnector(
                  fromLevel: level,
                  currentLevel: currentLevel,
                  completionRatio: widget.level.completionRatio,
                ),
            ],
            _buildTrailingHintDash(opacity: 0.42),
            _buildTrailingHintDash(opacity: 0.18),
          ],
        ),
      ),
    );
  }

  Widget _buildTrailingHintDash({required double opacity}) {
    return Padding(
      padding: EdgeInsets.only(right: 6),
      child: Container(
        width: 17,
        height: 7,
        decoration: BoxDecoration(
          color: AppColors.cFCFAFE.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(100),
        ),
      ),
    );
  }

  Widget _buildLevelNode(int level, int currentLevel) {
    final isValidated = level <= currentLevel;
    final focusLevel = currentLevel + 1;
    final key = level == focusLevel ? _focusLevelKey : null;

    return Container(
      key: key,
      width: 50,
      alignment: Alignment.center,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isValidated ? AppColors.cCFFFDD : null,
          gradient: !isValidated ? AppGradients.gB1BCFBToDBE7FE : null,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: isValidated
              ? const Icon(
                  Icons.check_rounded,
                  size: 20,
                  color: AppColors.c393566,
                  fontWeight: FontWeight.w700,
                )
              : Text(
                  '$level',
                  style: const TextStyle(
                    color: AppColors.c393566,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLevelConnector({
    required int fromLevel,
    required int currentLevel,
    required double completionRatio,
  }) {
    final filledCount = fromLevel < currentLevel
        ? 3
        : fromLevel == currentLevel
        ? (completionRatio * 3).round().clamp(0, 3)
        : 0;

    return Row(
      children: [
        for (var dashIndex = 0; dashIndex < 3; dashIndex++)
          Padding(
            padding: EdgeInsets.only(right: dashIndex < 2 ? 6 : 0),
            child: Container(
              width: 17,
              height: 7,
              decoration: BoxDecoration(
                color: dashIndex < filledCount
                    ? AppColors.cCFFFDD
                    : AppColors.whiteColor,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
      ],
    );
  }

  void _scrollToCurrentIfNeeded() {
    if (_didAutoScroll) return;
    _didAutoScroll = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentContext = _focusLevelKey.currentContext;
      if (currentContext == null) return;
      Scrollable.ensureVisible(
        currentContext,
        alignment: 0.5,
        duration: Duration.zero,
      );
    });
  }
}

class ShareProfileScreen extends StatefulWidget {
  const ShareProfileScreen({
    super.key,
    required this.userId,
    required this.username,
    this.avatarUrl,
  });

  final int userId;
  final String username;
  final String? avatarUrl;

  @override
  State<ShareProfileScreen> createState() => _ShareProfileScreenState();
}

class _ShareProfileScreenState extends State<ShareProfileScreen> {
  Future<void> _openShareToFriendsSheet(BuildContext context) async {
    final app = context.read<AppController>();
    final messenger = ScaffoldMessenger.of(context);
    final profileUserId = widget.userId;
    final profileUsername = widget.username.trim();

    if (profileUserId <= 0 || profileUsername.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Profil impossible a partager.')),
      );
      return;
    }

    final friends = _buildFriendTargets(app);
    if (friends.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Aucun ami disponible pour le partage.')),
      );
      return;
    }

    var query = '';
    final selectedUserIds = <int>{};
    var sending = false;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            final filteredFriends = friends
                .where(
                  (friend) =>
                      query.isEmpty ||
                      friend.username.toLowerCase().contains(query),
                )
                .toList(growable: false);
            final canSend = selectedUserIds.isNotEmpty && !sending;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetContext).size.height * 0.86,
              ),
              padding: EdgeInsets.fromLTRB(
                14,
                10,
                14,
                16 + MediaQuery.viewPaddingOf(sheetContext).bottom,
              ),
              decoration: BoxDecoration(
                gradient: AppGradients.gB1BCFBTo393566,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border.all(
                  color: AppColors.cFCFAFE.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.cFCFAFE.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Partager avec mes amis',
                    style: TextStyle(
                      color: AppColors.cFCFAFE,
                      fontFamily: AppTypography.displayFontFamily,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.cFCFAFE.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.cFCFAFE.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: AppColors.cFCFAFE,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            onChanged: (value) {
                              setModalState(
                                () => query = value.trim().toLowerCase(),
                              );
                            },
                            style: const TextStyle(
                              color: AppColors.cFCFAFE,
                              fontSize: 14,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Rechercher un ami',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isCollapsed: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: filteredFriends.isEmpty
                        ? const Center(
                            child: Text(
                              'Aucun ami trouve.',
                              style: TextStyle(color: AppColors.cDBE7FE),
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: filteredFriends.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final friend = filteredFriends[index];
                              final checked = selectedUserIds.contains(
                                friend.userId,
                              );
                              return InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: sending
                                    ? null
                                    : () {
                                        setModalState(() {
                                          if (checked) {
                                            selectedUserIds.remove(
                                              friend.userId,
                                            );
                                          } else {
                                            selectedUserIds.add(friend.userId);
                                          }
                                        });
                                      },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.cFCFAFE.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.cFCFAFE.withValues(
                                        alpha: checked ? 0.45 : 0.18,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      ClipOval(
                                        child: AppRemoteImage(
                                          url: friend.avatarUrl,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          fallbackIcon: Icons.person,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          friend.username,
                                          style: const TextStyle(
                                            color: AppColors.cFCFAFE,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Checkbox(
                                        value: checked,
                                        onChanged: sending
                                            ? null
                                            : (value) {
                                                setModalState(() {
                                                  if (value == true) {
                                                    selectedUserIds.add(
                                                      friend.userId,
                                                    );
                                                  } else {
                                                    selectedUserIds.remove(
                                                      friend.userId,
                                                    );
                                                  }
                                                });
                                              },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: !canSend
                          ? null
                          : () async {
                              setModalState(() => sending = true);
                              final sentCount = await app.shareProfileToUsers(
                                profileUserId: profileUserId,
                                profileUsername: profileUsername,
                                targetUserIds: selectedUserIds.toList(),
                              );
                              if (!sheetContext.mounted) return;
                              setModalState(() => sending = false);
                              if (app.errorMessage != null) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text(app.errorMessage!)),
                                );
                                return;
                              }
                              Navigator.of(sheetContext).pop();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    sentCount <= 1
                                        ? 'Profil partage en message prive.'
                                        : 'Profil partage a $sentCount amis.',
                                  ),
                                ),
                              );
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.cFCFAFE,
                        foregroundColor: AppColors.c121212,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        sending
                            ? 'Envoi en cours...'
                            : 'Envoyer (${selectedUserIds.length})',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<_ShareFriendTarget> _buildFriendTargets(AppController app) {
    final dedup = <int, _ShareFriendTarget>{};
    for (final friend in app.friends) {
      if (friend.status.trim().toUpperCase() != 'ACTIVE') continue;
      final friendId = friend.friendId;
      if (friendId <= 0) continue;
      final fromDetails = friend.friendDetails;
      UserModel? fallbackFromUsers;
      for (final user in app.allUsers) {
        if (user.id == friendId) {
          fallbackFromUsers = user;
          break;
        }
      }
      final username =
          (fromDetails?.username ?? fallbackFromUsers?.username ?? '').trim();
      if (username.isEmpty) continue;
      final avatarUrl = fromDetails?.avatar ?? fallbackFromUsers?.avatar;
      dedup[friendId] = _ShareFriendTarget(
        userId: friendId,
        username: username,
        avatarUrl: avatarUrl,
      );
    }
    final values = dedup.values.toList(growable: false);
    values.sort(
      (a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()),
    );
    return values;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final username = widget.username;
    final profileLink = 'https://anonym.app/u/$username';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.gB1BCFBTo393566),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(14),
                    child: Ink(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.cB1BCFB.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.cFCFAFE.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: AppColors.cFCFAFE,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  username,
                  style: t.displayMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 18),
                Container(
                  width: 232,
                  height: 232,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cFCFAFE,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: QrImageView(
                    data: profileLink,
                    version: QrVersions.auto,
                    gapless: true,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.c121212,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.c121212,
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: () => _openShareToFriendsSheet(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.cFCFAFE,
                      foregroundColor: AppColors.c121212,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: AppGradients.gCFFFDDToFCFAFE,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Partager',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontFamily: AppTypography.primaryFontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: profileLink));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lien copie.')),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.cFCFAFE,
                      foregroundColor: AppColors.c121212,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: AppGradients.gB1BCFBTo393566,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.cFCFAFE.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Copier le lien',
                          style: TextStyle(
                            color: AppColors.cFCFAFE,
                            fontFamily: AppTypography.primaryFontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Annuler',
                    style: TextStyle(
                      color: AppColors.cFCFAFE,
                      fontFamily: AppTypography.primaryFontFamily,
                      fontSize: 15,
                    ),
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

class _ShareFriendTarget {
  const _ShareFriendTarget({
    required this.userId,
    required this.username,
    required this.avatarUrl,
  });

  final int userId;
  final String username;
  final String? avatarUrl;
}

class _ReputationLinePainter extends CustomPainter {
  _ReputationLinePainter({required this.history});

  final List<PointsHistoryBucketModel> history;

  @override
  void paint(Canvas canvas, Size size) {
    final axis = Paint()
      ..color = AppColors.cFCFAFE.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = size.height * (i + 1) / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), axis);
    }

    final values = history
        .map((bucket) => bucket.pointsEarned.toDouble())
        .where((value) => value >= 0)
        .toList(growable: false);
    if (values.length < 2) return;

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    final path = Path();
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = (size.width * i) / (values.length - 1);
      final y = size.height - ((values[i] / safeMax) * (size.height * 0.9));
      points.add(Offset(x, y));
    }

    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final control = Offset((previous.dx + current.dx) / 2, previous.dy);
      final control2 = Offset((previous.dx + current.dx) / 2, current.dy);
      path.cubicTo(
        control.dx,
        control.dy,
        control2.dx,
        control2.dy,
        current.dx,
        current.dy,
      );
    }

    final stroke = Paint()
      ..color = AppColors.cCFFFDD
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _ReputationLinePainter oldDelegate) {
    return oldDelegate.history != history;
  }
}
