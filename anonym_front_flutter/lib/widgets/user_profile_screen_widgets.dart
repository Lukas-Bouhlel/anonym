part of '../screens/user_profile_screen.dart';

class _CommunityConversationTile extends StatelessWidget {
  const _CommunityConversationTile({
    required this.channel,
    required this.onTap,
  });

  final ChannelModel channel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.whiteColor.withValues(alpha: 0.12),
                width: 1,
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
                        color: Color(0xFFCCF0C8),
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
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      (channel.description ?? '').trim().isNotEmpty
                          ? channel.description!.trim()
                          : '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.cFCFAFE,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                '12:55 am',
                style: TextStyle(color: AppColors.cDBE7FE, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
