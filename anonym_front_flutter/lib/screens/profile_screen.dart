import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/points_summary_model.dart';
import '../models/user_model.dart';
import '../providers/app_providers.dart';
import '../providers/auth_providers.dart';
import '../services/points_repository.dart';
import '../theme.dart';
import '../utils/presence_utils.dart';
import '../widgets/app_remote_image.dart';
import '../widgets/presence_badge.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';


part '../widgets/profile_screen_widgets.dart';

/// Écran du profil de l utilisateur connecté.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<PointsSummaryModel> _pointsFuture;
  AppProvider? _appProvider;
  Timer? _pointsRealtimeDebounce;
  bool _isRealtimePointsReloadInFlight = false;
  int _lastSeenRealtimeStatsVersion = 0;

  @override
  void initState() {
    super.initState();
    _pointsFuture = _loadPoints();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = context.read<AppProvider>();
    if (identical(_appProvider, app)) return;
    _appProvider?.removeListener(_onAppProviderChanged);
    _appProvider = app;
    _lastSeenRealtimeStatsVersion = app.realtimeStatsVersion;
    _appProvider?.addListener(_onAppProviderChanged);
  }

  Future<PointsSummaryModel> _loadPoints() {
    return context.read<PointsRepository>().readMe();
  }

  Future<void> _reloadPoints() async {
    if (!mounted) return;
    final future = _loadPoints();
    setState(() => _pointsFuture = future);
    await future;
  }

  void _onAppProviderChanged() {
    final app = _appProvider;
    if (!mounted || app == null) return;
    final nextVersion = app.realtimeStatsVersion;
    if (nextVersion == _lastSeenRealtimeStatsVersion) return;
    _lastSeenRealtimeStatsVersion = nextVersion;
    _pointsRealtimeDebounce?.cancel();
    _pointsRealtimeDebounce = Timer(const Duration(milliseconds: 220), () {
      unawaited(_reloadPointsFromRealtimeSignal());
    });
  }

  Future<void> _reloadPointsFromRealtimeSignal() async {
    if (!mounted || _isRealtimePointsReloadInFlight) return;
    _isRealtimePointsReloadInFlight = true;
    try {
      await _reloadPoints();
    } catch (_) {
      // Keep realtime refresh best-effort and silent for profile points.
    } finally {
      _isRealtimePointsReloadInFlight = false;
    }
  }

  @override
  void dispose() {
    _pointsRealtimeDebounce?.cancel();
    _appProvider?.removeListener(_onAppProviderChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isCurrentUser = user != null;
    final t = Theme.of(context).textTheme;

    return Consumer<AppProvider>(
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
          color: AppColors.whiteColor,
          backgroundColor: AppColors.primary,
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
                              PageRouteBuilder<void>(
                                transitionDuration: const Duration(
                                  milliseconds: 260,
                                ),
                                reverseTransitionDuration: const Duration(
                                  milliseconds: 220,
                                ),
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        const SettingsScreen(),
                                transitionsBuilder:
                                    (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) {
                                      final offset =
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
                                        position: offset,
                                        child: child,
                                      );
                                    },
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
                                PageRouteBuilder<void>(
                                  transitionDuration: const Duration(
                                    milliseconds: 260,
                                  ),
                                  reverseTransitionDuration: const Duration(
                                    milliseconds: 220,
                                  ),
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => const EditProfileScreen(),
                                  transitionsBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                        child,
                                      ) {
                                        final offset =
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
                                          position: offset,
                                          child: child,
                                        );
                                      },
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
                              '${points.totals.messagesCount} messages sur une période de ${points.period == 'day'
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
    required AppProvider app,
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
