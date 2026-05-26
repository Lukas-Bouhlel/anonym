import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/inventory_item_model.dart';
import '../models/shop_item_model.dart';
import '../providers/app_providers.dart';
import '../providers/auth_providers.dart';
import '../theme.dart';
import '../widgets/app_remote_image.dart';
import '../widgets/navigation/anonym_back_button.dart';


part '../widgets/inventory_screen_widgets.dart';

/// Écran d inventaire des éléments possédés par l utilisateur.
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
      final app = context.read<AppProvider>();
      app.refreshInventory(silent: true);
      app.refreshShop(silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.gB1BCFBTo393566),
        child: SafeArea(
          child: Consumer<AppProvider>(
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
                        const AnonymBackButton(),
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
                      title: selectedShop?.title ?? 'Aucune décoration',
                      subtitle: selectedShop == null
                          ? 'Selectionne une décoration ci-dessous'
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
                          'Tes décoration',
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
                        'Va jeter un oeil à la boutique',
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
  if (value == null) return 'Acquise récemment';
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
