import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/channel_model.dart';
import '../models/user_model.dart';
import '../providers/app_controller.dart';
import '../providers/auth_controller.dart';
import '../theme.dart';
import '../widgets/app_remote_image.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final me = context.watch<AuthController>().user;
    final t = Theme.of(context).textTheme;
    String formatDate(DateTime dt) {
      const months = [
        'janvier',
        'février',
        'mars',
        'avril',
        'mai',
        'juin',
        'juillet',
        'août',
        'septembre',
        'octobre',
        'novembre',
        'décembre',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    }

    DateTime? memberSinceDate = user.createdAt;
    if (memberSinceDate == null && user.id > 0) {
      for (final candidate in app.allUsers) {
        if (candidate.id == user.id) {
          memberSinceDate = candidate.createdAt;
          break;
        }
      }
    }

    final memberSince = memberSinceDate != null
        ? formatDate(memberSinceDate)
        : '';
    final isOwnProfile = me?.id == user.id;
    final publicCommunities = app.channels
        .where((channel) {
          final isPublicGroup =
              channel.channelType.trim().toUpperCase() == 'GROUP' &&
              channel.visibility.trim().toUpperCase() == 'PUBLIC';
          if (!isPublicGroup) return false;
          if (isOwnProfile) return true;
          return channel.createdBy == user.id;
        })
        .toList(growable: false);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.gB1BCFBTo393566),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Container(
            decoration: const BoxDecoration(
              gradient: AppGradients.gB1BCFBTo393566,
            ),
            child: Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          width: 86,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.cFCFAFE.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppGradients.gB1BCFBTo393566,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: AppColors.cFCFAFE.withValues(alpha: 0.50),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: AppRemoteImage(
                                      url: user.avatar,
                                      width: 60,
                                      height: 60,
                                      fallbackIcon: Icons.person,
                                    ),
                                  ),
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF97F6C1),
                                      border: Border.all(
                                        color: AppColors.cFCFAFE,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.username,
                                      style: t.displayMedium?.copyWith(
                                        height: 0.9,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      (user.bio ?? '').trim().isEmpty
                                          ? ''
                                          : user.bio!,
                                      style: const TextStyle(
                                        color: AppColors.cDBE7FE,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.cB1BCFB.withValues(
                                    alpha: 0.18,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.more_vert,
                                  color: AppColors.cFCFAFE,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppGradients.gB1BCFBTo393566,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: AppColors.cFCFAFE.withValues(alpha: 0.50),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Membre depuis',
                                      style: TextStyle(
                                        color: AppColors.cFCFAFE,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 13),
                                    Text(
                                      memberSince,
                                      style: const TextStyle(
                                        color: AppColors.cDBE7FE,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Container(
                              //   padding: const EdgeInsets.symmetric(
                              //     horizontal: 12,
                              //     vertical: 6,
                              //   ),
                              //   decoration: BoxDecoration(
                              //     gradient: AppGradients.gD09EFEToD0BAFF,
                              //     borderRadius: BorderRadius.circular(16),
                              //     boxShadow: [
                              //       BoxShadow(
                              //         color: AppColors.c393566.withOpacity(
                              //           0.14,
                              //         ),
                              //         blurRadius: 10,
                              //         offset: const Offset(0, 4),
                              //       ),
                              //     ],
                              //   ),
                              //   child: const Text(
                              //     'LVL 45',
                              //     style: TextStyle(
                              //       color: AppColors.cFCFAFE,
                              //       fontWeight: FontWeight.w800,
                              //     ),
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Communautés',
                          style: const TextStyle(
                            fontFamily: AppTypography.displayFontFamily,
                            fontWeight: FontWeight.w600,
                            fontSize: 25,
                            letterSpacing: -0.8,
                            height: 1.1,
                            color: AppColors.whiteColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: AppGradients.gB1BCFBTo393566,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.cFCFAFE.withValues(
                                  alpha: 0.50,
                                ),
                              ),
                            ),
                            child: publicCommunities.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Aucune communaute publique.',
                                      style: TextStyle(
                                        color: AppColors.cDBE7FE,
                                        fontSize: 13,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    itemCount: publicCommunities.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 2),
                                    itemBuilder: (context, index) {
                                      final channel = publicCommunities[index];
                                      return _CommunityConversationTile(
                                        channel: channel,
                                        onTap: () async {
                                          await app.selectChannel(channel);
                                          if (!context.mounted) return;
                                          Navigator.of(context).pop();
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: FilledButton(
                                  onPressed: () {},
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.c393566,
                                    foregroundColor: AppColors.cFCFAFE,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: AppColors.cFCFAFE.withValues(
                                          alpha: 0.50,
                                        ),
                                      ),
                                    ),
                                  ),
                                  child: const Text(
                                    'Envoyer un message',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontFamily: AppTypography.primaryFontFamily,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 56,
                              height: 46,
                              decoration: BoxDecoration(
                                gradient: AppGradients.gB1BCFBTo393566,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.c393566.withOpacity(0.18),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.reply_rounded,
                                  color: AppColors.cFCFAFE,
                                  size: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
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
                          : 'Lorem ipsum ...',
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
