part of '../../screens/channels_screen.dart';

String? _dmPeerFrameUrl(UserModel? user) {
  if (user == null || user.id <= 0) return null;
  for (final item in user.inventories) {
    if (!item.active) continue;
    if (item.userId > 0 && item.userId != user.id) continue;
    final shop = item.shop;
    if (shop == null) continue;
    if (shop.type.trim().toUpperCase() != 'CADRE') continue;
    final content = shop.content.trim();
    if (content.isNotEmpty) return content;
  }
  return null;
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.channel,
    required this.onTap,
    this.dmPresenceStatus,
    this.dmPresenceLabel,
  });

  final ChannelModel channel;
  final VoidCallback onTap;
  final String? dmPresenceStatus;
  final String? dmPresenceLabel;

  @override
  Widget build(BuildContext context) {
    final isDm = channel.channelType.trim().toUpperCase() == 'PRIVATE_DM';
    final dmPeer = channel.dmPeer;
    final dmPeerName = (dmPeer?.username ?? '').trim();
    final title = isDm && dmPeerName.isNotEmpty ? dmPeerName : channel.name;
    final avatarUrl = isDm ? dmPeer?.avatar : channel.coverImage;
    final dmPeerFrameUrl = isDm ? _dmPeerFrameUrl(dmPeer) : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.whiteColor.withValues(alpha: 0.12),
                width: 1.24,
              ),
            ),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: isDm
                        ? Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipOval(
                                child: AppRemoteImage(
                                  url: avatarUrl,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  fallbackIcon: Icons.person,
                                ),
                              ),
                              if (dmPeerFrameUrl != null)
                                IgnorePointer(
                                  child: AppRemoteImage(
                                    url: dmPeerFrameUrl,
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                            ],
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: AppGradients.gB1BCFBTo393566,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.whiteColor.withValues(
                                  alpha: 0.24,
                                ),
                                width: 1.24,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AppRemoteImage(
                                url: avatarUrl,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                fallbackIcon: Icons.alternate_email,
                              ),
                            ),
                          ),
                  ),
                  if (isDm)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: PresenceBadge(
                        presenceStatus:
                            dmPresenceStatus ?? PresenceUtils.offline,
                        isCurrentUser: false,
                        size: 12,
                        borderColor: AppColors.cFCFAFE,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: AppTypography.displayFontFamily,
                        color: AppColors.cFCFAFE,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isDm)
                      Text(
                        dmPresenceLabel ?? 'Hors-ligne',
                        style: const TextStyle(
                          color: AppColors.cDBE7FE,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else
                      _ChannelTypeBadge(channel: channel),
                  ],
                ),
              ),
              Column(
                children: [
                  const Text(
                    '12:55',
                    style: TextStyle(color: AppColors.cDBE7FE, fontSize: 13),
                  ),
                  if (channel.unreadCount > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        channel.unreadCount.toString(),
                        style: const TextStyle(
                          color: AppColors.cFCFAFE,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChannelTypeBadge extends StatelessWidget {
  const _ChannelTypeBadge({required this.channel});

  final ChannelModel channel;

  @override
  Widget build(BuildContext context) {
    final type = channel.channelType.trim().toUpperCase();
    final visibility = channel.visibility.trim().toUpperCase();
    final isDm = type == 'PRIVATE_DM';
    final label = isDm
        ? 'DM'
        : visibility == 'PUBLIC'
        ? 'GROUPE PUBLIC'
        : 'GROUPE PRIVE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.cFCFAFE.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.cFCFAFE.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.cFCFAFE,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
