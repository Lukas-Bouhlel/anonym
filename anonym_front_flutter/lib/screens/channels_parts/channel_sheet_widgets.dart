part of '../channels_screen.dart';

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final normalized = label.trim().toUpperCase();
    final isPrivate = normalized == 'PRIVATE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: isPrivate
            ? AppGradients.gB1BCFBTo393566
            : AppGradients.gCFFFDDToFCFAFE,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.cFCFAFE.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isPrivate ? AppColors.cFCFAFE : AppColors.c393566,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.cFCFAFE.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cFCFAFE.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.cFCFAFE, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.cFCFAFE,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.cDBE7FE),
          ],
        ),
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.member});

  final UserModel member;

  @override
  Widget build(BuildContext context) {
    final frameUrl = _activeFrameUrl(member);
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.cFCFAFE.withValues(alpha: 0.28),
              ),
            ),
            child: ClipOval(
              child: AppRemoteImage(
                url: member.avatar,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
                fallbackIcon: Icons.person_outline,
              ),
            ),
          ),
          if (frameUrl != null)
            IgnorePointer(
              child: AppRemoteImage(
                url: frameUrl,
                width: 43,
                height: 43,
                fit: BoxFit.contain,
              ),
            ),
        ],
      ),
    );
  }

  String? _activeFrameUrl(UserModel user) {
    for (final item in user.inventories) {
      if (!item.active) continue;
      if (item.userId != user.id) continue;
      final shop = item.shop;
      if (shop == null) continue;
      if (shop.type.trim().toUpperCase() != 'CADRE') continue;
      final content = shop.content.trim();
      if (content.isNotEmpty) return content;
    }
    return null;
  }
}
