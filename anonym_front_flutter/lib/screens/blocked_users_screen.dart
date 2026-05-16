import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_controller.dart';
import '../theme.dart';
import '../widgets/app_remote_image.dart';
import '../widgets/chrome/moji_back_button.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppController>().refreshBlockedUsers(silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.gB1BCFBTo393566),
        child: SafeArea(
          child: Consumer<AppController>(
            builder: (context, app, _) {
              final blocked = app.blockedUsers;
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                children: [
                  Row(
                    children: [
                      const MojiBackButton(),
                      const SizedBox(width: 14),
                      Text(
                        'Utilisateurs bloqués',
                        style: t.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  if (blocked.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cB1BCFB.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.cFCFAFE.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Text(
                        'Aucun utilisateur bloque.',
                        style: TextStyle(
                          color: AppColors.cDBE7FE,
                          fontSize: 15,
                        ),
                      ),
                    )
                  else
                    ...blocked.map(
                      (user) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _BlockedUserCard(
                          username: user.username,
                          avatarUrl: user.avatar,
                          onUnblock: () => app.unblockUser(user.id),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BlockedUserCard extends StatelessWidget {
  const _BlockedUserCard({
    required this.username,
    required this.avatarUrl,
    required this.onUnblock,
  });

  final String username;
  final String? avatarUrl;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: AppGradients.gB1BCFBTo393566,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.whiteColor.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AppRemoteImage(
              url: avatarUrl,
              width: 38,
              height: 38,
              fallbackIcon: Icons.person_outline_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.whiteColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppGradients.gB1BCFBTo393566,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SizedBox(
              height: 40,
              child: TextButton(
                onPressed: onUnblock,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.whiteColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Débloquer',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
