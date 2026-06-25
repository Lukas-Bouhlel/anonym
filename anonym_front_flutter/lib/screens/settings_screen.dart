import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/app_providers.dart';
import '../providers/auth_providers.dart';
import '../routes/app_routes.dart';
import '../theme.dart';
import '../widgets/app_remote_image.dart';
import '../widgets/navigation/anonym_back_button.dart';
import '../widgets/dialogs/anonym_confirm_dialog.dart';
import 'edit_profile_screen.dart';
import 'inventory_screen.dart';
import 'invoices_screen.dart';
import 'shop_screen.dart';
import 'password_screen.dart';
import 'blocked_users_screen.dart';
import 'faq_screen.dart';
import 'feedback_screen.dart';
import 'notifications_screen.dart';


part '../widgets/settings_screen_widgets.dart';

/// Écran de paramètres utilisateur.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _pushSlide(BuildContext context, Widget child) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final offset =
              Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );
          return SlideTransition(position: offset, child: child);
        },
      ),
    );
  }

  Future<bool> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AnonymConfirmDialog(
        type: AnonymConfirmDialogType.warning,
        title: 'Se déconnecter ?',
        description: 'Tu vas être déconnecté de ton compte sur cet appareil.',
        confirmLabel: 'Se déconnecter',
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
      builder: (dialogContext) => AnonymConfirmDialog(
        type: AnonymConfirmDialogType.danger,
        title: 'Supprimer le compte ?',
        description:
            'Cette action est définitive. Ton compte et tes données seront supprimés.',
        confirmLabel: 'Supprimer le compte',
        onConfirm: () => Navigator.of(dialogContext).pop(true),
        onCancel: () => Navigator.of(dialogContext).pop(false),
      ),
    );
    return confirmed == true;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final auth = context.watch<AuthProvider>();
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
                  const AnonymBackButton(),
                  const SizedBox(width: 14),
                  Text('Paramètres', style: t.displayLarge),
                ],
              ),
              const SizedBox(height: 24),
              _CardContainer(
                child: InkWell(
                  onTap: () => _pushSlide(context, const EditProfileScreen()),
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
                    onTap: () => _pushSlide(context, const InventoryScreen()),
                  ),
                  _SettingsItem(
                    label: 'Boutique',
                    onTap: () => _pushSlide(context, const ShopScreen()),
                  ),
                  _SettingsItem(
                    label: 'Factures',
                    onTap: () => _pushSlide(context, const InvoicesScreen()),
                  ),
                  _SettingsItem(
                    label: 'Changer le mot de passe',
                    onTap: () => _pushSlide(context, const PasswordScreen()),
                  ),
                  _SettingsItem(
                    label: 'Utilisateurs bloqués',
                    onTap: () =>
                        _pushSlide(context, const BlockedUsersScreen()),
                  ),
                  _SettingsItem(
                    label: 'Notifications',
                    onTap: () =>
                        _pushSlide(context, const NotificationsScreen()),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('ASSISTANCE', style: t.titleMedium),
              const SizedBox(height: 12),
              _SectionCard(
                items: [
                  _SettingsItem(
                    label: 'FAQ',
                    onTap: () => _pushSlide(context, const FaqScreen()),
                  ),
                  _SettingsItem(
                    label: 'Feedback',
                    onTap: () => _pushSlide(context, const FeedbackScreen()),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('JURIDIQUE', style: t.titleMedium),
              const SizedBox(height: 12),
              const _SectionCard(
                items: [
                  _SettingsItem(label: 'Conditions générales'),
                  _SettingsItem(label: 'Mentions légales'),
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
                label: const Text('Se déconnecter'),
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
