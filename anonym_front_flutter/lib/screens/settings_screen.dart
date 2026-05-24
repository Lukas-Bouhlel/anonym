import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/app_controller.dart';
import '../providers/auth_controller.dart';
import '../routes/app_routes.dart';
import '../theme.dart';
import '../widgets/app_remote_image.dart';
import '../widgets/chrome/moji_back_button.dart';
import '../widgets/modals/moji_confirm_modal.dart';
import 'edit_profile_screen.dart';
import 'inventory_screen.dart';
import 'invoices_screen.dart';
import 'shop_screen.dart';
import 'password_screen.dart';
import 'blocked_users_screen.dart';
import 'faq_screen.dart';
import 'feedback_screen.dart';
import 'notifications_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<bool> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => MojiConfirmModal(
        title: 'Se deconnecter ?',
        description: 'Tu vas etre deconnecte de ton compte sur cet appareil.',
        confirmLabel: 'Se deconnecter',
        onConfirm: () => Navigator.of(dialogContext).pop(true),
        onCancel: () => Navigator.of(dialogContext).pop(false),
      ),
    );
    return confirmed == true;
  }

  Future<bool> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => MojiConfirmModal(
        title: 'Supprimer le compte ?',
        description:
            'Cette action est definitive. Ton compte et tes donnees seront supprimes.',
        confirmLabel: 'Supprimer le compte',
        confirmGradient: const [AppColors.danger, AppColors.danger],
        onConfirm: () => Navigator.of(dialogContext).pop(true),
        onCancel: () => Navigator.of(dialogContext).pop(false),
      ),
    );
    return confirmed == true;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final auth = context.watch<AuthController>();
    final user = auth.user;
    final t = Theme.of(context).textTheme;
    final activeItem = app.inventoryItems
        .where((item) => item.active)
        .toList(growable: false);
    String activeDecoration = '';
    if (activeItem.isNotEmpty) {
      final firstActive = activeItem.first;
      final fromInventory = (firstActive.shop?.content ?? '').trim();
      if (fromInventory.isNotEmpty) {
        activeDecoration = fromInventory;
      } else {
        activeDecoration = app.shopItems
            .where((shop) => shop.articleId == firstActive.articleId)
            .map((shop) => shop.content.trim())
            .firstWhere((url) => url.isNotEmpty, orElse: () => '');
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.gB1BCFBTo393566),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
            children: [
              Row(
                children: [
                  const MojiBackButton(),
                  const SizedBox(width: 14),
                  Text('Paramètres', style: t.displayLarge),
                ],
              ),
              const SizedBox(height: 24),
              _CardContainer(
                child: InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.cABB7DF,
                              child: ClipOval(
                                child: AppRemoteImage(
                                  url: user?.avatar,
                                  width: 40,
                                  height: 40,
                                  fallbackIcon: Icons.person_rounded,
                                ),
                              ),
                            ),
                            if (activeDecoration.isNotEmpty)
                              AppRemoteImage(
                                url: activeDecoration,
                                width: 42,
                                height: 42,
                                fit: BoxFit.contain,
                                fallbackIcon: Icons.blur_on_rounded,
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
                              user?.username ?? 'Utilisateur',
                              style: const TextStyle(
                                color: AppColors.cFCFAFE,
                                fontWeight: FontWeight.w700,
                                fontSize: 22,
                              ),
                            ),
                            const Text(
                              'Modifier le profil',
                              style: TextStyle(color: AppColors.cDBE7FE),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.cFCFAFE,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('PROFIL', style: t.titleMedium),
              const SizedBox(height: 12),
              _SectionCard(
                items: [
                  _SettingsItem(
                    label: 'Inventaire',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const InventoryScreen(),
                      ),
                    ),
                  ),
                  _SettingsItem(
                    label: 'Boutique',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ShopScreen()),
                    ),
                  ),
                  _SettingsItem(
                    label: 'Factures',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const InvoicesScreen()),
                    ),
                  ),
                  _SettingsItem(
                    label: 'Changer le mot de passe',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PasswordScreen()),
                    ),
                  ),
                  _SettingsItem(
                    label: 'Utilisateurs bloqués',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BlockedUsersScreen(),
                      ),
                    ),
                  ),
                  _SettingsItem(
                    label: 'Notifications',
                    onTap: () => Navigator.of(context).push(
                      PageRouteBuilder<void>(
                        transitionDuration: const Duration(milliseconds: 260),
                        reverseTransitionDuration: const Duration(
                          milliseconds: 220,
                        ),
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const NotificationsScreen(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
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
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('ASSISTANCE', style: t.titleMedium),
              const SizedBox(height: 12),
              _SectionCard(
                items: [
                  _SettingsItem(
                    label: 'FAQs',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FaqScreen()),
                    ),
                  ),
                  _SettingsItem(
                    label: 'Feedback',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('JURIDIQUE', style: t.titleMedium),
              const SizedBox(height: 12),
              const _SectionCard(
                items: [
                  _SettingsItem(label: 'Conditions generales'),
                  _SettingsItem(label: 'Mentions legales'),
                ],
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: auth.isBusy
                    ? null
                    : () async {
                        final confirmed = await _confirmLogout(context);
                        if (!confirmed) return;
                        await auth.logout();
                        if (!context.mounted) return;
                        context.go(AppRoutes.auth);
                      },
                icon: const Icon(Icons.logout),
                label: const Text('Se deconnecter'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.cFCFAFE,
                  side: BorderSide(
                    color: AppColors.cFCFAFE.withValues(alpha: 0.38),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: auth.isBusy || app.isSubmitting
                    ? null
                    : () async {
                        final confirmed = await _confirmDeleteAccount(context);
                        if (!confirmed) return;
                        await app.deleteAccount();
                        if (!context.mounted) return;
                        if (app.errorMessage != null &&
                            app.errorMessage!.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(app.errorMessage!)),
                          );
                          return;
                        }
                        context.go(AppRoutes.auth);
                      },
                icon: const Icon(Icons.delete_forever_rounded),
                label: const Text('Supprimer le compte'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: BorderSide(
                    color: AppColors.danger.withValues(alpha: 0.7),
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

class _CardContainer extends StatelessWidget {
  const _CardContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppGradients.gB1BCFBTo393566,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cFCFAFE.withValues(alpha: 0.35)),
      ),
      child: child,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.items});

  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.gB1BCFBTo393566,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cFCFAFE.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _SettingsRow(item: items[i]),
            if (i < items.length - 1)
              Divider(
                height: 1,
                color: AppColors.cFCFAFE.withValues(alpha: 0.25),
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.item});

  final _SettingsItem item;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Expanded(child: Text(item.label, style: t.bodyMedium)),
            const Icon(Icons.chevron_right, color: AppColors.cDBE7FE),
          ],
        ),
      ),
    );
  }
}

class _SettingsItem {
  const _SettingsItem({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;
}
