part of '../screens/channels_screen.dart';

/// Secondary screen dedicated to public channels discovery/join flow.
///
/// This widget is declared as a `part` of `channels_screen.dart` and expects
/// provider dependencies already available in the surrounding screen tree.
///
/// {@tool snippet}
/// Navigator.of(context).push(
///   MaterialPageRoute(
///     builder: (_) => const PublicConversationsScreen(),
///   ),
/// );
/// {@end-tool}
///
/// Error cases:
/// - If `ChannelsProvider` is missing in context, reads like
///   `context.read<ChannelsProvider>()` throw at runtime.
class PublicConversationsScreen extends StatefulWidget {
  const PublicConversationsScreen({super.key});

  @override
  State<PublicConversationsScreen> createState() =>
      _PublicConversationsScreenState();
}

class _PublicConversationsScreenState extends State<PublicConversationsScreen>
    with WidgetsBindingObserver {
  String _query = '';
  String _filter = 'all';
  final Map<String, int> _countsByFilter = {
    'all': 0,
    'joined': 0,
    'discover': 0,
  };
  bool _isSwitchingFilter = false;
  bool _isRealtimeRefreshing = false;
  int _filterRequestVersion = 0;
  Timer? _realtimeTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final app = context.read<ChannelsProvider>();
      setState(() {
        _countsByFilter[_filter] = app.publicChannels.length;
      });
      _loadFilter(app, _filter, showLoader: true);
      _startRealtimeRefresh();
    });
  }

  @override
  void dispose() {
    _realtimeTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    _refreshRealtime();
  }

  void _startRealtimeRefresh() {
    _realtimeTimer?.cancel();
    _realtimeTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _refreshRealtime();
    });
  }

  Future<void> _refreshCountsForAll(ChannelsProvider app) async {
    try {
      final responses = await Future.wait([
        app.loadJoinDirectoryChannels(filter: 'all'),
        app.loadJoinDirectoryChannels(filter: 'joined'),
        app.loadJoinDirectoryChannels(filter: 'discover'),
      ]);
      if (!mounted) return;
      setState(() {
        _countsByFilter['all'] = responses[0].length;
        _countsByFilter['joined'] = responses[1].length;
        _countsByFilter['discover'] = responses[2].length;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _countsByFilter[_filter] = app.publicChannels.length;
      });
    }
  }

  Future<void> _refreshRealtime() async {
    if (!mounted || _isRealtimeRefreshing || _isSwitchingFilter) return;
    _isRealtimeRefreshing = true;
    final app = context.read<ChannelsProvider>();
    final activeFilter = _filter;
    try {
      await Future.wait([
        app.refreshChannels(silent: true),
        app.refreshPublicChannels(filter: activeFilter, silent: true),
      ]);
      if (!mounted) return;
      setState(() {
        _countsByFilter[activeFilter] = app.publicChannels.length;
      });
    } finally {
      _isRealtimeRefreshing = false;
    }
  }

  Future<void> _loadFilter(
    ChannelsProvider app,
    String filter, {
    bool showLoader = false,
  }) async {
    final requestVersion = ++_filterRequestVersion;
    if (showLoader) {
      setState(() => _isSwitchingFilter = true);
    }
    await app.refreshPublicChannels(filter: filter, silent: true);
    if (!mounted || requestVersion != _filterRequestVersion) return;
    setState(() {
      _countsByFilter[filter] = app.publicChannels.length;
      _isSwitchingFilter = false;
    });
    unawaited(_refreshCountsForAll(app));
  }

  bool _isPublicGroupChannel(ChannelModel channel) {
    final type = channel.channelType.trim().toUpperCase();
    final visibility = channel.visibility.trim().toUpperCase();
    return type == 'GROUP' && visibility == 'PUBLIC';
  }

  Future<void> _handleJoinChannelTap(
    BuildContext context,
    ChannelsProvider app,
    ChannelModel channel,
    bool joined,
  ) async {
    if (joined) {
      await app.selectChannel(channel);
    } else {
      await app.joinPublicChannel(channel.channelId, publicFilter: _filter);
      final joinedChannel = app.channels
          .where((it) => it.channelId == channel.channelId)
          .toList(growable: false);
      if (joinedChannel.isNotEmpty) {
        await app.selectChannel(joinedChannel.first);
      }
    }
    if (!context.mounted) return;
    final error = app.errorMessage;
    if (error != null && error.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.gB1BCFBTo393566),
        child: SafeArea(
          child: Builder(
            builder: (context) {
              final app = context.read<ChannelsProvider>();
              final allPublicChannels = context
                  .select<ChannelsProvider, List<ChannelModel>>(
                    (provider) => provider.publicChannels,
                  )
                  .toList(growable: false);
              final joinedIds = context
                  .select<ChannelsProvider, List<ChannelModel>>(
                    (provider) => provider.channels,
                  )
                  .map((channel) => channel.channelId)
                  .toSet();
              bool resolveJoined(ChannelModel channel) {
                final category = (channel.listCategory ?? '')
                    .trim()
                    .toLowerCase();
                if (channel.isJoined != null) return channel.isJoined!;
                if (category == 'joined') return true;
                if (category == 'discover') return false;
                return joinedIds.contains(channel.channelId);
              }

              final normalizedQuery = _query.trim().toLowerCase();
              bool matchesQuery(ChannelModel channel) {
                final haystack = '${channel.name} ${channel.description ?? ''}'
                    .toLowerCase();
                return normalizedQuery.isEmpty ||
                    haystack.contains(normalizedQuery);
              }

              final filtered = allPublicChannels
                  .where(matchesQuery)
                  .toList(growable: false);

              final discoverTop =
                  allPublicChannels
                      .where(_isPublicGroupChannel)
                      .toList(growable: false)
                    ..sort(
                      (a, b) => (b.reputationScore ?? 0).compareTo(
                        a.reputationScore ?? 0,
                      ),
                    );
              final discoverTop10 = discoverTop
                  .take(10)
                  .toList(growable: false);
              final discoverRankById = <int, int>{
                for (var i = 0; i < discoverTop10.length; i++)
                  discoverTop10[i].channelId: i + 1,
              };
              final discoverVisible = discoverTop10
                  .where(matchesQuery)
                  .toList(growable: false);

              return RefreshIndicator(
                color: AppColors.whiteColor,
                backgroundColor: AppColors.primary,
                onRefresh: () async {
                  await Future.wait([
                    app.refreshChannels(silent: true),
                    app.refreshPublicChannels(filter: _filter, silent: true),
                  ]);
                  if (!mounted) return;
                  setState(() {
                    _countsByFilter[_filter] = app.publicChannels.length;
                  });
                  await _refreshCountsForAll(app);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  children: [
                    Row(
                      children: [
                        const AnonymBackButton(),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Rejoindre',
                            style: TextStyle(
                              fontFamily: AppTypography.displayFontFamily,
                              color: AppColors.cFCFAFE,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 11.45),
                      decoration: BoxDecoration(
                        gradient: AppGradients.gB1BCFBTo393566,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            color: AppColors.whiteColor,
                            size: 27,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              onChanged: (value) =>
                                  setState(() => _query = value),
                              style: const TextStyle(
                                color: AppColors.whiteColor,
                                fontFamily: AppTypography.primaryFontFamily,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                              cursorColor: AppColors.whiteColor,
                              decoration: const InputDecoration(
                                hintText: 'Rechercher une conversation',
                                hintStyle: TextStyle(
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
                    const SizedBox(height: 10),
                    _PublicFilterBar(
                      selected: _filter,
                      allCount: _countsByFilter['all'] ?? 0,
                      joinedCount: _countsByFilter['joined'] ?? 0,
                      discoverCount: _countsByFilter['discover'] ?? 0,
                      onSelected: (value) {
                        if (_filter == value) return;
                        setState(() => _filter = value);
                        _loadFilter(app, value, showLoader: true);
                      },
                    ),
                    const SizedBox(height: 10),
                    if (_isSwitchingFilter)
                      const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.cFCFAFE,
                          ),
                        ),
                      )
                    else if ((_filter == 'discover'
                            ? discoverVisible
                            : filtered)
                        .isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(
                          child: Text(
                            'Aucune conversation publique trouvée.',
                            style: TextStyle(color: AppColors.cDBE7FE),
                          ),
                        ),
                      )
                    else if (_filter == 'discover') ...[
                      const _DiscoverTopIntro(),
                      const SizedBox(height: 10),
                      ...discoverVisible.map((channel) {
                        final joined = resolveJoined(channel);
                        final rank = discoverRankById[channel.channelId] ?? 0;
                        return _DiscoverTopChannelTile(
                          channel: channel,
                          rank: rank,
                          joined: joined,
                          onActionTap: () => _handleJoinChannelTap(
                            context,
                            app,
                            channel,
                            joined,
                          ),
                        );
                      }),
                    ] else
                      ...filtered.map((channel) {
                        final joined = resolveJoined(channel);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cFCFAFE.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.cFCFAFE.withValues(alpha: 0.16),
                            ),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: AppRemoteImage(
                                  url: channel.coverImage,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  fallbackIcon: Icons.groups_rounded,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      channel.name,
                                      style: const TextStyle(
                                        color: AppColors.cFCFAFE,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      (channel.description ?? '').trim().isEmpty
                                          ? 'Groupe public'
                                          : channel.description!.trim(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.cDBE7FE,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () => _handleJoinChannelTap(
                                  context,
                                  app,
                                  channel,
                                  joined,
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.cFCFAFE,
                                  backgroundColor: AppColors.cFCFAFE.withValues(
                                    alpha: 0.10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(joined ? 'Ouvrir' : 'Rejoindre'),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PublicFilterBar extends StatelessWidget {
  const _PublicFilterBar({
    required this.selected,
    required this.allCount,
    required this.joinedCount,
    required this.discoverCount,
    required this.onSelected,
  });

  final String selected;
  final int allCount;
  final int joinedCount;
  final int discoverCount;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PublicFilterChip(
            label: 'Top',
            count: discoverCount,
            isActive: selected == 'discover',
            onTap: () => onSelected('discover'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PublicFilterChip(
            label: 'Rejoints',
            count: joinedCount,
            isActive: selected == 'joined',
            onTap: () => onSelected('joined'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PublicFilterChip(
            label: 'Tous',
            count: allCount,
            isActive: selected == 'all',
            onTap: () => onSelected('all'),
          ),
        ),
      ],
    );
  }
}

class _PublicFilterChip extends StatelessWidget {
  const _PublicFilterChip({
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

class _DiscoverTopIntro extends StatelessWidget {
  const _DiscoverTopIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x4DFFD06A), Color(0x33D09EFE)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cFCFAFE.withValues(alpha: 0.24)),
      ),
      child: const Row(
        children: [
          Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD06A), size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Top 10 des groupes publics par réputation',
              style: TextStyle(
                color: AppColors.cFCFAFE,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverTopChannelTile extends StatelessWidget {
  const _DiscoverTopChannelTile({
    required this.channel,
    required this.rank,
    required this.joined,
    required this.onActionTap,
  });

  final ChannelModel channel;
  final int rank;
  final bool joined;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    final score = channel.reputationScore ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        gradient: AppGradients.gB1BCFBTo393566,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cFCFAFE.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          _DiscoverRankBadge(rank: rank),
          const SizedBox(width: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AppRemoteImage(
              url: channel.coverImage,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              fallbackIcon: Icons.groups_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  channel.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.cFCFAFE,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cFCFAFE.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.cFCFAFE.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: Color(0xFFFFC86A),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Score: $score',
                        style: const TextStyle(
                          color: AppColors.cFCFAFE,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.cFCFAFE,
              backgroundColor: AppColors.cFCFAFE.withValues(alpha: 0.12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(joined ? 'Ouvrir' : 'Rejoindre'),
          ),
        ],
      ),
    );
  }
}

class _DiscoverRankBadge extends StatelessWidget {
  const _DiscoverRankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final colors = _rankColors(rank);
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cFCFAFE.withValues(alpha: 0.35)),
      ),
      alignment: Alignment.center,
      child: Text(
        '#$rank',
        style: const TextStyle(
          color: AppColors.c121212,
          fontWeight: FontWeight.w800,
          fontSize: 12.5,
        ),
      ),
    );
  }

  List<Color> _rankColors(int value) {
    if (value == 1) return const [Color(0xFFFFE08A), Color(0xFFFFC34D)];
    if (value == 2) return const [Color(0xFFE9EFFA), Color(0xFFBCC7DB)];
    if (value == 3) return const [Color(0xFFF4C9A2), Color(0xFFD9946D)];
    return const [Color(0xFFDCC8FF), Color(0xFFBFA0F7)];
  }
}
