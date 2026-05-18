part of '../channels_screen.dart';

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.channel, required this.onTap});

  final ChannelModel channel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppGradients.gB1BCFBTo393566,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.whiteColor.withValues(alpha: 0.24),
                        width: 1.24,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AppRemoteImage(
                        url: channel.coverImage,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        fallbackIcon: Icons.alternate_email,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppColors.cCFFFDD,
                        shape: BoxShape.circle,
                      ),
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
                      channel.name,
                      style: const TextStyle(
                        fontFamily: AppTypography.displayFontFamily,
                        color: AppColors.cFCFAFE,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
