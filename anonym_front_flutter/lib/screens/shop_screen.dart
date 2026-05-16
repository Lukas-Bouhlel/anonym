import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/app_controller.dart';
import '../providers/auth_controller.dart';
import '../theme.dart';
import '../widgets/app_remote_image.dart';
import '../widgets/chrome/moji_back_button.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = context.read<AppController>();
      app.refreshShop(silent: true);
      app.refreshInventory(silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.gB1BCFBTo393566),
        child: SafeArea(
          child: Consumer<AppController>(
            builder: (context, app, _) {
              return RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([app.refreshShop(), app.refreshInventory()]);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                  children: [
                    Row(
                      children: [
                        const MojiBackButton(),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Boutique',
                            style: t.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Trouve ton style',
                      style: t.titleMedium?.copyWith(
                        color: AppColors.whiteColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (app.shopItems.isEmpty)
                      const _SoftCard(
                        child: Padding(
                          padding: EdgeInsets.all(18),
                          child: Text(
                            'Aucun article disponible pour le moment.',
                            style: TextStyle(color: AppColors.cFCFAFE),
                          ),
                        ),
                      )
                    else
                      ...app.shopItems.map((item) {
                        final owned = app.isArticleOwned(item.articleId);
                        final inventoryItem = app.inventoryByArticleId(
                          item.articleId,
                        );
                        final isActive = inventoryItem?.active == true;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ShopPreviewCard(
                            username: user?.username ?? 'Anonym',
                            avatarUrl: user?.avatar,
                            frameUrl: item.content,
                            title: item.title,
                            priceLabel: _formatPrice(item.amount),
                            owned: owned,
                            isActive: isActive,
                            onTap: () => _openItemDetails(
                              context: context,
                              app: app,
                              username: user?.username ?? 'Anonym',
                              avatarUrl: user?.avatar,
                              title: item.title,
                              frameUrl: item.content,
                              priceLabel: _formatPrice(item.amount),
                              owned: owned,
                              isActive: isActive,
                              onBuy: () =>
                                  _buyItem(context, app, item.articleId),
                              onActivate: inventoryItem == null
                                  ? null
                                  : () => _activateNow(
                                        context,
                                        app,
                                        inventoryItem.itemId,
                                      ),
                            ),
                          ),
                        );
                      }),
                    if (app.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          app.errorMessage!,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _buyItem(
    BuildContext context,
    AppController app,
    int articleId,
  ) async {
    final url = await app.startCheckout(articleId);
    if (!context.mounted) return;

    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(app.errorMessage ?? 'Paiement indisponible')),
      );
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL de paiement invalide')),
      );
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openItemDetails({
    required BuildContext context,
    required AppController app,
    required String username,
    required String? avatarUrl,
    required String title,
    required String frameUrl,
    required String priceLabel,
    required bool owned,
    required bool isActive,
    required Future<void> Function() onBuy,
    required Future<void> Function()? onActivate,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.84,
          child: Container(
            decoration: const BoxDecoration(
              gradient: AppGradients.gB1BCFBTo393566,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.whiteColor.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _AvatarPreview(
                      avatarUrl: avatarUrl,
                      frameUrl: frameUrl,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.c393566.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.whiteColor.withValues(alpha: 0.45),
                        ),
                      ),
                      child: const Text(
                        'Decoration d\'avatar',
                        style: TextStyle(
                          color: AppColors.cFCFAFE,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.cFCFAFE,
                        fontWeight: FontWeight.w700,
                        fontSize: 19,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Donne un nouveau look a ton avatar.',
                      style: const TextStyle(
                        color: AppColors.whiteColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      owned ? 'Obtenu' : priceLabel,
                      style: const TextStyle(
                        color: AppColors.whiteColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: owned
                          ? DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: AppGradients.gB1BCFBTo393566,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: FilledButton(
                                onPressed: onActivate == null
                                    ? null
                                    : () async {
                                        await onActivate();
                                        if (!sheetContext.mounted) return;
                                        Navigator.of(sheetContext).pop();
                                      },
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: AppColors.whiteColor,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(
                                      color: AppColors.whiteColor,
                                      width: 0.25,
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  'Utiliser maintenant',
                                  style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                            )
                          : DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: AppGradients.gB1BCFBTo393566,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: FilledButton(
                                onPressed: app.isSubmitting
                                    ? null
                                    : () async {
                                        await onBuy();
                                        if (!sheetContext.mounted) return;
                                        Navigator.of(sheetContext).pop();
                                      },
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: AppColors.whiteColor,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(
                                      color: AppColors.whiteColor,
                                      width: 0.25,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Acheter pour $priceLabel',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _activateNow(
    BuildContext context,
    AppController app,
    int itemId,
  ) async {
    await app.activateInventoryItem(itemId, true);
    if (!context.mounted) return;
    if (app.errorMessage != null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ta décoration d\'avatar à été mise à jour !'),
      ),
    );
  }
}

String _formatPrice(int amount) {
  if (amount >= 100) {
    final euros = (amount / 100).toStringAsFixed(2).replaceAll('.', ',');
    return '$euros €';
  }
  return '$amount €';
}

class _ShopPreviewCard extends StatelessWidget {
  const _ShopPreviewCard({
    required this.username,
    required this.avatarUrl,
    required this.frameUrl,
    required this.title,
    required this.priceLabel,
    required this.owned,
    required this.isActive,
    required this.onTap,
  });

  final String username;
  final String? avatarUrl;
  final String frameUrl;
  final String title;
  final String priceLabel;
  final bool owned;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: _SoftCard(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AvatarPreview(
                avatarUrl: avatarUrl,
                frameUrl: frameUrl,
                showUserAvatar: false,
                showOwnedBadge: owned,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.cFCFAFE,
                  fontWeight: FontWeight.w700,
                  fontSize: 19,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                owned ? 'Obtenu' : priceLabel,
                style: TextStyle(
                  color: owned
                      ? (isActive
                            ? AppColors.whiteColor
                            : AppColors.whiteColor.withValues(alpha: 0.35))
                      : AppColors.cFCFAFE,
                  fontWeight: owned ? FontWeight.w500 : FontWeight.w700,
                  fontSize: owned ? 16 : 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({
    required this.avatarUrl,
    required this.frameUrl,
    this.showUserAvatar = true,
    this.showOwnedBadge = false,
  });

  final String? avatarUrl;
  final String? frameUrl;
  final bool showUserAvatar;
  final bool showOwnedBadge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 170,
            height: 170,
            child: showUserAvatar
                ? ClipOval(
                    child: AppRemoteImage(
                      url: avatarUrl,
                      width: 170,
                      height: 170,
                      fallbackIcon: Icons.person,
                    ),
                  )
                : Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF1F2230),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: SvgPicture.asset(
                      'assets/icons/anonym_logo.svg',
                      width: 88,
                      height: 88,
                      colorFilter: ColorFilter.mode(
                        AppColors.cFCFAFE.withValues(alpha: 0.35),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
          ),
          if (showOwnedBadge)
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.whiteColor,
                size: 44,
              ),
            ),
          if ((frameUrl ?? '').isNotEmpty)
            AppRemoteImage(
              url: frameUrl,
              width: 174,
              height: 174,
              fit: BoxFit.contain,
              fallbackIcon: Icons.blur_on_rounded,
            ),
        ],
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.gB1BCFBTo393566,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cFCFAFE.withValues(alpha: 0.2)),
      ),
      child: child,
    );
  }
}
