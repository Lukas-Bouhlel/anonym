import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme.dart';

/// Glass-style back button used in modal/sheet headers.
///
/// {@tool snippet}
/// AnonymBackButton(
///   onTap: () => Navigator.of(context).maybePop(),
/// )
/// {@end-tool}
///
/// Error cases:
/// - If this widget is used in a route without a navigator ancestor, the
///   default fallback tap (`maybePop`) does nothing.
class AnonymBackButton extends StatelessWidget {
  const AnonymBackButton({
    super.key,
    this.onTap,
    this.size = 40,
    this.iconSize = 30,
  });

  final VoidCallback? onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.of(context).maybePop(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.whiteColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.whiteColor.withValues(alpha: 0.12),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.c121212.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.chevron_left_rounded,
              size: iconSize,
              color: AppColors.whiteColor,
            ),
          ),
        ),
      ),
    );
  }
}
