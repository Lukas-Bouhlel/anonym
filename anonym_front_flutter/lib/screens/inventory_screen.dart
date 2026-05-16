import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/inventory_item_model.dart';
import '../models/shop_item_model.dart';
import '../providers/app_controller.dart';
import '../providers/auth_controller.dart';
import '../theme.dart';
import '../widgets/app_remote_image.dart';
import '../widgets/chrome/moji_back_button.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  int? _selectedItemId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = context.read<AppController>();
      app.refreshInventory(silent: true);
      app.refreshShop(silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.gB1BCFBTo393566),
        child: SafeArea(
          child: Consumer<AppController>(
            builder: (context, app, _) {
              final ownedItems = app.inventoryItems;
              final ownedArticleIds = ownedItems
                  .map((e) => e.articleId)
                  .toSet();
              final shopPreviewItems = app.shopItems
                  .where((s) => !ownedArticleIds.contains(s.articleId))
                  .take(6)
                  .toList(growable: false);

              if (_selectedItemId == null && ownedItems.isNotEmpty) {
                final active = ownedItems.where((e) => e.active).toList();
                _selectedItemId =
                    (active.isNotEmpty ? active.first : ownedItems.first)
                        .itemId;
              }

              InventoryItemModel? selected;
              if (_selectedItemId != null) {
                for (final item in ownedItems) {
                  if (item.itemId == _selectedItemId) {
                    selected = item;
                    break;
                  }
                }
              }
              selected ??= ownedItems.isNotEmpty ? ownedItems.first : null;
              final selectedShop = selected?.shop;
              final selectedItem = selected;

              return RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    app.refreshInventory(),
                    app.refreshShop(),
                  ]);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  children: [
                    Row(
                      children: [
                        const MojiBackButton(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Inventaire',
                            style: t.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _PreviewCard(
                      username: user?.username ?? 'Utilisateur',
                      avatarUrl: user?.avatar,
                      frameUrl: selectedShop?.content,
                      title: selectedShop?.title ?? 'Aucune decoration',
                      subtitle: selectedShop == null
                          ? 'Selectionne une decoration ci-dessous'
                          : _formatAcquiredDate(selected?.createdAt),
                      isActive: selected?.active ?? false,
                      onAction: selectedItem == null
                          ? null
                          : () => app.activateInventoryItem(
                              selectedItem.itemId,
                              !selectedItem.active,
                            ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Tes decorations',
                          style: t.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (ownedItems.isEmpty)
                      _EmptyOwnedCard(onShopTap: () {})
                    else
                      GridView.builder(
                        itemCount: ownedItems.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1,
                            ),
                        itemBuilder: (context, index) {
                          final item = ownedItems[index];
                          final isSelected = item.itemId == selected?.itemId;
                          return _OwnedDecorationTile(
                            imageUrl: item.shop?.content,
                            title: item.shop?.title ?? 'Item',
                            selected: isSelected,
                            active: item.active,
                            onTap: () =>
                                setState(() => _selectedItemId = item.itemId),
                          );
                        },
                      ),
                    const SizedBox(height: 18),
                    if (shopPreviewItems.isNotEmpty) ...[
                      Text(
                        'Va jeter un oeil a la boutique',
                        style: t.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GridView.builder(
                        itemCount: shopPreviewItems.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1,
                            ),
                        itemBuilder: (context, index) {
                          final item = shopPreviewItems[index];
                          return _ShopPreviewTile(item: item);
                        },
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

String _formatAcquiredDate(DateTime? value) {
  if (value == null) return 'Acquise recemment';
  const months = [
    'janvier',
    'fevrier',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'aout',
    'septembre',
    'octobre',
    'novembre',
    'decembre',
  ];
  final month = months[value.month - 1];
  return 'Acquise en $month ${value.year}';
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.username,
    required this.avatarUrl,
    required this.frameUrl,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.onAction,
  });

  final String username;
  final String? avatarUrl;
  final String? frameUrl;
  final String title;
  final String subtitle;
  final bool isActive;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppGradients.gB1BCFBTo393566,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cFCFAFE.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 165,
                  height: 165,
                  child: ClipOval(
                    child: AppRemoteImage(
                      url: avatarUrl,
                      width: 165,
                      height: 165,
                      fallbackIcon: Icons.person,
                    ),
                  ),
                ),
                if ((frameUrl ?? '').isNotEmpty)
                  AppRemoteImage(
                    url: frameUrl,
                    width: 166,
                    height: 166,
                    fallbackIcon: Icons.blur_on_rounded,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: AppColors.c393566.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.cFCFAFE.withValues(alpha: 0.28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.cFCFAFE,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.cDBE7FE),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: isActive
                    ? AppColors.c393566
                    : AppColors.cFCFAFE,
                foregroundColor: isActive
                    ? AppColors.cFCFAFE
                    : AppColors.c393566,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: AppColors.cFCFAFE.withValues(alpha: 0.35),
                  ),
                ),
              ),
              child: Text(
                isActive ? 'Retirer' : 'Appliquer',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFamily: AppTypography.primaryFontFamily,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnedDecorationTile extends StatelessWidget {
  const _OwnedDecorationTile({
    required this.imageUrl,
    required this.title,
    required this.selected,
    required this.active,
    required this.onTap,
  });

  final String? imageUrl;
  final String title;
  final bool selected;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.c393566.withValues(alpha: selected ? 0.6 : 0.36),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.cFCFAFE.withValues(alpha: 0.9)
                : AppColors.cFCFAFE.withValues(alpha: 0.25),
            width: selected ? 2 : 1.1,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: AppRemoteImage(
                  url: imageUrl,
                  fit: BoxFit.contain,
                  fallbackIcon: Icons.blur_on_rounded,
                ),
              ),
            ),
            if (active)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.cCFFFDD,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 13,
                    color: AppColors.c393566,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShopPreviewTile extends StatelessWidget {
  const _ShopPreviewTile({required this.item});

  final ShopItemModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.c393566.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cFCFAFE.withValues(alpha: 0.2)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: AppRemoteImage(
                url: item.content,
                fit: BoxFit.contain,
                fallbackIcon: Icons.lock_outline_rounded,
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.cFCFAFE.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 12,
                color: AppColors.cFCFAFE,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyOwnedCard extends StatelessWidget {
  const _EmptyOwnedCard({required this.onShopTap});

  final VoidCallback onShopTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppGradients.gB1BCFBTo393566,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cFCFAFE.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            color: AppColors.cFCFAFE,
            size: 28,
          ),
          const SizedBox(height: 10),
          const Text(
            'Aucune decoration possedee',
            style: TextStyle(
              color: AppColors.cFCFAFE,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onShopTap,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: AppColors.cFCFAFE.withValues(alpha: 0.35),
              ),
            ),
            child: const Text(
              'Voir la boutique',
              style: TextStyle(color: AppColors.cFCFAFE),
            ),
          ),
        ],
      ),
    );
  }
}
