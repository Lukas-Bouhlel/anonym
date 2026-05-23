import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_notification_model.dart';
import '../models/user_model.dart';
import '../providers/app_controller.dart';
import '../screens/user_profile_screen.dart';
import '../theme.dart';
import '../widgets/chrome/moji_back_button.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppController>().markAllNotificationsAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final notifications = context.watch<AppController>().notifications;
    final grouped = _groupNotificationsByDay(notifications);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.gB1BCFBTo393566),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            children: [
              Row(
                children: [
                  const MojiBackButton(),
                  const SizedBox(width: 14),
                  Text('Notifications', style: t.displayLarge),
                ],
              ),
              const SizedBox(height: 26),
              if (notifications.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.whiteColor.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Text(
                    'Aucune notification pour le moment.',
                    style: t.bodyMedium?.copyWith(color: AppColors.cDBE7FE),
                  ),
                )
              else
                ...grouped.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: t.titleSmall?.copyWith(
                            color: AppColors.whiteColor.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _NotificationGroup(
                          items: entry.value,
                          onTap: _onNotificationTap,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, List<AppNotificationModel>> _groupNotificationsByDay(
    List<AppNotificationModel> items,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final grouped = <String, List<AppNotificationModel>>{};
    for (final item in items) {
      final date = item.createdAt.toLocal();
      final keyDate = DateTime(date.year, date.month, date.day);
      final key = keyDate == today
          ? "AUJOURD'HUI"
          : keyDate == yesterday
          ? 'HIER'
          : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      grouped.putIfAbsent(key, () => <AppNotificationModel>[]).add(item);
    }
    return grouped;
  }

  Future<void> _onNotificationTap(AppNotificationModel item) async {
    final app = context.read<AppController>();
    if (item.type == AppNotificationType.newMessage &&
        item.relatedChannelId != null) {
      final opened = await app.openChannelById(item.relatedChannelId!);
      if (!mounted) return;
      if (opened) {
        Navigator.of(context).maybePop();
      } else if (app.errorMessage != null && app.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(app.errorMessage!)));
      }
      return;
    }
    if (item.type == AppNotificationType.friendRequest &&
        item.relatedUserId != null) {
      UserModel? user;
      for (final candidate in app.allUsers) {
        if (candidate.id == item.relatedUserId) {
          user = candidate;
          break;
        }
      }
      user ??= _findUserFromIncomingRequests(app, item.relatedUserId!);
      if (user == null) {
        await app.refreshUsers(silent: true);
        for (final candidate in app.allUsers) {
          if (candidate.id == item.relatedUserId) {
            user = candidate;
            break;
          }
        }
      }
      if (!mounted) return;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil utilisateur introuvable.')),
        );
        return;
      }
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
        builder: (_) => FractionallySizedBox(
          heightFactor: 0.86,
          child: UserProfileScreen(user: user!),
        ),
      );
      return;
    }
    Navigator.of(context).maybePop();
  }

  UserModel? _findUserFromIncomingRequests(AppController app, int userId) {
    for (final request in app.incomingFriendRequests) {
      final details = request.friendDetails;
      if (details != null && details.id == userId) return details;
    }
    return null;
  }
}

class _NotificationGroup extends StatelessWidget {
  const _NotificationGroup({required this.items, required this.onTap});

  final List<AppNotificationModel> items;
  final ValueChanged<AppNotificationModel> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x3026262D), Color(0x14222330)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.whiteColor.withValues(alpha: 0.24),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _NotificationTile(item: items[i], onTap: onTap),
            if (i < items.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Divider(
                  height: 1,
                  color: AppColors.whiteColor.withValues(alpha: 0.2),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final AppNotificationModel item;
  final ValueChanged<AppNotificationModel> onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(item),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  Positioned(
                    left: -1,
                    top: -1,
                    child: _UnreadDot(visible: !item.isRead),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.whiteColor,
                      fontFamily: AppTypography.primaryFontFamily,
                      fontSize: 31 / 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      color: AppColors.whiteColor.withValues(alpha: 0.68),
                      fontFamily: AppTypography.primaryFontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Color(0xFFFF4D2D),
        shape: BoxShape.circle,
      ),
    );
  }
}
