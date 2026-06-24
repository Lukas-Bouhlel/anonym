part of '../screens/profile_screen.dart';

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

/// Secondary screen used to share a profile with friends.
///
/// This widget is declared as a `part` of `profile_screen.dart` and relies on
/// `SocialProvider` and `AuthProvider` from the parent context.
///
/// {@tool snippet}
/// Navigator.of(context).push(
///   MaterialPageRoute(
///     builder: (_) => ShareProfileScreen(
///       userId: user.id,
///       username: user.username,
///       avatarUrl: user.avatar,
///     ),
///   ),
/// );
/// {@end-tool}
///
/// Error cases:
/// - [userId] <= 0 or empty [username] prevents share actions and shows a
///   `SnackBar` error.
/// - Missing provider ancestors can throw provider lookup exceptions.
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
  String? _activeFrameUrlForUser(SocialProvider social, int userId) {
    if (userId <= 0) return null;
    UserModel? source;
    final authUser = context.read<AuthProvider>().user;
    if (authUser != null && authUser.id == userId) {
      source = authUser;
    } else {
      for (final candidate in social.allUsers) {
        if (candidate.id == userId) {
          source = candidate;
          break;
        }
      }
    }
    if (source == null) return null;
    for (final item in source.inventories) {
      if (!item.active) continue;
      final shop = item.shop;
      if (shop == null) continue;
      final content = shop.content.trim();
      if (content.isEmpty) continue;
      if (shop.type.trim().toUpperCase() == 'CADRE') return content;
    }
    return null;
  }

  Future<void> _openShareToFriendsSheet(BuildContext context) async {
    final social = context.read<SocialProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final profileUserId = widget.userId;
    final profileUsername = widget.username.trim();

    if (profileUserId <= 0 || profileUsername.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Profil impossible à partager.')),
      );
      return;
    }

    final friends = _buildFriendTargets(social);
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
            final bottomSafe = MediaQuery.of(sheetContext).padding.bottom;

            return Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              padding: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                gradient: AppGradients.gB1BCFBTo393566,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border.all(
                  color: AppColors.cFCFAFE.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: SizedBox(
                height: MediaQuery.of(sheetContext).size.height * 0.78,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.cFCFAFE.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const Text(
                      'Partager avec mes amis',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.cFCFAFE,
                        fontFamily: AppTypography.displayFontFamily,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Divider(
                      height: 1,
                      color: AppColors.cFCFAFE.withValues(alpha: 0.18),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          14,
                          10,
                          14,
                          16 + bottomSafe,
                        ),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                gradient: AppGradients.gB1BCFBTo393566,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.cFCFAFE.withValues(
                                    alpha: 0.20,
                                  ),
                                ),
                              ),
                              child: TextField(
                                onChanged: (value) {
                                  setModalState(
                                    () => query = value.trim().toLowerCase(),
                                  );
                                },
                                style: const TextStyle(
                                  color: AppColors.cFCFAFE,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Rechercher des amis',
                                  hintStyle: TextStyle(
                                    color: AppColors.cFCFAFE.withValues(
                                      alpha: 0.55,
                                    ),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    color: AppColors.cFCFAFE,
                                  ),
                                  filled: false,
                                  fillColor: Colors.transparent,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: filteredFriends.isEmpty
                                  ? Center(
                                      child: Text(
                                        'Aucun ami à inviter',
                                        style: TextStyle(
                                          color: AppColors.cFCFAFE.withValues(
                                            alpha: 0.8,
                                          ),
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: filteredFriends.length,
                                      separatorBuilder: (_, _) => Divider(
                                        height: 1,
                                        color: AppColors.cFCFAFE.withValues(
                                          alpha: 0.12,
                                        ),
                                      ),
                                      itemBuilder: (context, index) {
                                        final friend = filteredFriends[index];
                                        final checked = selectedUserIds
                                            .contains(friend.userId);
                                        return ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          onTap: sending
                                              ? null
                                              : () {
                                                  setModalState(() {
                                                    if (checked) {
                                                      selectedUserIds.remove(
                                                        friend.userId,
                                                      );
                                                    } else {
                                                      selectedUserIds.add(
                                                        friend.userId,
                                                      );
                                                    }
                                                  });
                                                },
                                          leading: SizedBox(
                                            width: 42,
                                            height: 42,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Container(
                                                  width: 42,
                                                  height: 42,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.c393566,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: AppColors.cFCFAFE
                                                          .withValues(
                                                            alpha: 0.18,
                                                          ),
                                                    ),
                                                  ),
                                                  child: ClipOval(
                                                    child: AppRemoteImage(
                                                      url: friend.avatarUrl,
                                                      width: 40,
                                                      height: 40,
                                                      fit: BoxFit.cover,
                                                      fallbackIcon:
                                                          Icons.person_outline,
                                                    ),
                                                  ),
                                                ),
                                                if (friend.frameUrl != null)
                                                  IgnorePointer(
                                                    child: AppRemoteImage(
                                                      url: friend.frameUrl,
                                                      width: 42,
                                                      height: 42,
                                                      fit: BoxFit.contain,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          title: Text(
                                            friend.username,
                                            style: const TextStyle(
                                              color: AppColors.cFCFAFE,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          trailing: SizedBox(
                                            width: 34,
                                            height: 34,
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: checked
                                                    ? AppColors.cFCFAFE
                                                          .withValues(
                                                            alpha: 0.20,
                                                          )
                                                    : AppColors.cFCFAFE
                                                          .withValues(
                                                            alpha: 0.08,
                                                          ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: AppColors.cFCFAFE
                                                      .withValues(alpha: 0.28),
                                                ),
                                              ),
                                              child: Checkbox(
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
                                                            selectedUserIds
                                                                .remove(
                                                                  friend.userId,
                                                                );
                                                          }
                                                        });
                                                      },
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                side: BorderSide(
                                                  color: AppColors.cFCFAFE
                                                      .withValues(alpha: 0.60),
                                                  width: 1.4,
                                                ),
                                                checkColor: AppColors.c393566,
                                                activeColor: AppColors.cFCFAFE,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: canSend
                                      ? AppGradients.gB1BCFBTo393566
                                      : null,
                                  color: canSend
                                      ? null
                                      : AppColors.cFCFAFE.withValues(
                                          alpha: 0.08,
                                        ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.cFCFAFE.withValues(
                                      alpha: 0.25,
                                    ),
                                  ),
                                ),
                                child: FilledButton(
                                  onPressed: !canSend
                                      ? null
                                      : () async {
                                          setModalState(() => sending = true);
                                          final sentCount = await social
                                              .shareProfileToUsers(
                                                profileUserId: profileUserId,
                                                profileUsername:
                                                    profileUsername,
                                                targetUserIds: selectedUserIds
                                                    .toList(),
                                                profileAvatarUrl:
                                                    widget.avatarUrl,
                                                profileFrameUrl:
                                                    _activeFrameUrlForUser(
                                                      social,
                                                      profileUserId,
                                                    ),
                                              );
                                          if (!sheetContext.mounted) return;
                                          setModalState(() => sending = false);
                                          if (social.errorMessage != null) {
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  social.errorMessage!,
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                          Navigator.of(sheetContext).pop();
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                sentCount <= 1
                                                    ? 'Profil partagé en message privé.'
                                                    : 'Profil partagé à $sentCount amis.',
                                              ),
                                            ),
                                          );
                                        },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    disabledBackgroundColor: Colors.transparent,
                                    foregroundColor: AppColors.cFCFAFE,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    sending
                                        ? 'Envoi en cours...'
                                        : 'Envoyer (${selectedUserIds.length})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
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
            );
          },
        );
      },
    );
  }

  List<_ShareFriendTarget> _buildFriendTargets(SocialProvider social) {
    final dedup = <int, _ShareFriendTarget>{};
    for (final friend in social.friends) {
      if (friend.status.trim().toUpperCase() != 'ACTIVE') continue;
      final friendId = friend.friendId;
      if (friendId <= 0) continue;
      final fromDetails = friend.friendDetails;
      UserModel? fallbackFromUsers;
      for (final user in social.allUsers) {
        if (user.id == friendId) {
          fallbackFromUsers = user;
          break;
        }
      }
      final username =
          (fromDetails?.username ?? fallbackFromUsers?.username ?? '').trim();
      if (username.isEmpty) continue;
      final avatarUrl = fromDetails?.avatar ?? fallbackFromUsers?.avatar;
      final frameUrl = _activeFrameUrlForUser(social, friendId);
      dedup[friendId] = _ShareFriendTarget(
        userId: friendId,
        username: username,
        avatarUrl: avatarUrl,
        frameUrl: frameUrl,
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
    required this.frameUrl,
  });

  final int userId;
  final String username;
  final String? avatarUrl;
  final String? frameUrl;
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
