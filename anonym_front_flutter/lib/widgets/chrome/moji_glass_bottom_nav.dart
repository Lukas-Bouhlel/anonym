import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme.dart';

class MojiGlassBottomNav extends StatelessWidget {
  const MojiGlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onCenterTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onCenterTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      left: false,
      right: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: AppGradients.gB1BCFBTo393566,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: 0.58,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.c393566.withValues(alpha: 0.36),
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _NavItem(
                        icon: _buildHomeIcon(currentIndex == 0),
                        label: 'Home',
                        isActive: currentIndex == 0,
                        onTap: () => onTap(0),
                      ),
                      _NavItem(
                        icon: Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 24,
                          color: AppColors.whiteColor.withValues(
                            alpha: currentIndex == 1 ? 1 : 0.52,
                          ),
                        ),
                        label: 'Chat',
                        isActive: currentIndex == 1,
                        onTap: () => onTap(1),
                      ),
                      _CenterButton(onTap: onCenterTap),
                      _NavItem(
                        icon: Icon(
                          Icons.search_rounded,
                          size: 25,
                          color: AppColors.whiteColor.withValues(
                            alpha: currentIndex == 2 ? 1 : 0.52,
                          ),
                        ),
                        label: 'Search',
                        isActive: currentIndex == 2,
                        onTap: () => onTap(2),
                      ),
                      _NavItem(
                        icon: Icon(
                          Icons.person_outline_rounded,
                          size: 25,
                          color: AppColors.whiteColor.withValues(
                            alpha: currentIndex == 3 ? 1 : 0.52,
                          ),
                        ),
                        label: 'Profile',
                        isActive: currentIndex == 3,
                        onTap: () => onTap(3),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeIcon(bool isActive) {
    return SizedBox(
      width: 24,
      height: 24,
      child: SvgPicture.asset(
        'assets/icons/anonym_logo.svg',
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(
          AppColors.whiteColor.withValues(alpha: isActive ? 1 : 0.5),
          BlendMode.srcIn,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 50,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 24, height: 24, child: icon),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.primaryFontFamily,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                fontSize: 20 / 1.8,
                color: AppColors.whiteColor.withValues(
                  alpha: isActive ? 1 : 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterButton extends StatelessWidget {
  const _CenterButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.whiteColor.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.whiteColor.withValues(alpha: 0.22),
            width: 1.15,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: const Icon(Icons.add, size: 28, color: AppColors.whiteColor),
      ),
    );
  }
}
