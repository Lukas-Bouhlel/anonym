part of '../screens/inventory_screen.dart';

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
            'Aucune décoration possédée',
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
