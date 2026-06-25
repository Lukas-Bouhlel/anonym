import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_providers.dart';
import '../theme.dart';
import '../widgets/app_remote_image.dart';
import '../widgets/navigation/anonym_back_button.dart';
import '../widgets/dialogs/anonym_confirm_dialog.dart';
import '../widgets/presence_badge.dart';

/// Écran de gestion des utilisateurs bloqués.
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
      context.read<AppProvider>().refreshBlockedUsers(silent: true);
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
          child: Consumer<AppProvider>(
            builder: (context, app, _) {
              final blocked = app.blockedUsers;
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                children: [
                  Row(
                    children: [
                      const AnonymBackButton(),
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
                        'Aucun utilisateur bloqué.',
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
                          userId: user.id,
                          presenceStatus: app.presenceStatusForUser(user.id),
                          username: user.username,
                          avatarUrl: user.avatar,
                          onUnblock: () => _confirmAndUnblock(user.id),
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

  Future<void> _confirmAndUnblock(int userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AnonymConfirmDialog(
        type: AnonymConfirmDialogType.warning,
        title: 'Débloquer cet utilisateur ?',
        description: 'Il pourra de nouveau te contacter et interagir avec toi.',
        confirmLabel: 'Débloquer',
        onConfirm: () => Navigator.of(dialogContext).pop(true),
        onCancel: () => Navigator.of(dialogContext).pop(false),
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<AppProvider>().unblockUser(userId);
  }
}

class _BlockedUserCard extends StatelessWidget {
  const _BlockedUserCard({
    required this.userId,
    required this.presenceStatus,
    required this.username,
    required this.avatarUrl,
    required this.onUnblock,
  });

  final int userId;
  final String presenceStatus;
  final String username;
  final String? avatarUrl;
  final Future<void> Function() onUnblock;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: AppGradients.gB1BCFBTo393566,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.whiteColor.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Stack(
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
              Positioned(
                right: -1,
                top: -1,
                child: PresenceBadge(
                  presenceStatus: presenceStatus,
                  isCurrentUser: false,
                  size: 10,
                  borderColor: AppColors.cFCFAFE,
                ),
              ),
            ],
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
                onPressed: () async => onUnblock(),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.whiteColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Débloquer',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
