part of '../screens/shop_screen.dart';

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
