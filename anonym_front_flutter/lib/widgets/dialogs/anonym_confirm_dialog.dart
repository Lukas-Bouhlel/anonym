import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme.dart';

/// Visual variants for [AnonymConfirmDialog].
///
/// - `success`: positive confirmation action.
/// - `warning`: neutral/attention action.
/// - `danger`: destructive action.
enum AnonymConfirmDialogType { success, warning, danger }

/// Reusable confirmation dialog for success/warning/danger flows.
///
/// {@tool snippet}
/// showDialog(
///   context: context,
///   builder: (_) => AnonymConfirmDialog(
///     title: 'Delete message?',
///     description: 'This action cannot be undone.',
///     confirmLabel: 'Delete',
///     type: AnonymConfirmDialogType.danger,
///     onConfirm: () {
///       Navigator.of(context).pop();
///       // perform delete
///     },
///   ),
/// );
/// {@end-tool}
///
/// Error cases:
/// - Dialog icons depend on SVG assets; missing asset declarations can throw
///   runtime load errors.
/// - If [onConfirm] is null, the confirm button is rendered disabled.
class AnonymConfirmDialog extends StatelessWidget {
  const AnonymConfirmDialog({
    super.key,
    required this.title,
    required this.description,
    required this.confirmLabel,
    this.cancelLabel = 'Annuler',
    this.type = AnonymConfirmDialogType.warning,
    this.confirmGradient,
    this.backgroundColor = Colors.transparent,
    this.onConfirm,
    this.onCancel,
  });

  final String title;
  final String description;
  final String confirmLabel;
  final String cancelLabel;
  final AnonymConfirmDialogType type;
  final List<Color>? confirmGradient;
  final Color backgroundColor;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  String get _iconAssetPath {
    switch (type) {
      case AnonymConfirmDialogType.success:
        return 'assets/icons/success.svg';
      case AnonymConfirmDialogType.danger:
        return 'assets/icons/danger.svg';
      case AnonymConfirmDialogType.warning:
        return 'assets/icons/warning.svg';
    }
  }

  Size get _iconSize {
    switch (type) {
      case AnonymConfirmDialogType.success:
        return const Size(74, 74);
      case AnonymConfirmDialogType.danger:
        return const Size(65, 65);
      case AnonymConfirmDialogType.warning:
        return const Size(74, 65);
    }
  }

  List<Color> get _resolvedConfirmGradient {
    if (confirmGradient != null && confirmGradient!.isNotEmpty) {
      return confirmGradient!;
    }
    switch (type) {
      case AnonymConfirmDialogType.success:
        return const [Color(0xFF25BA72), Color(0xFF25BA72)];
      case AnonymConfirmDialogType.danger:
        return const [Color(0xFFFF5B4F), Color(0xFFFF5B4F)];
      case AnonymConfirmDialogType.warning:
        return const [AppColors.c393566, AppColors.c393566];
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = _iconSize;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.fromLTRB(28, 36, 28, 24),
        decoration: BoxDecoration(
          gradient: AppGradients.gB1BCFBTo393566,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 90,
              height: 80,
              child: Center(
                child: SvgPicture.asset(
                  _iconAssetPath,
                  width: iconSize.width,
                  height: iconSize.height,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTypography.displayFontFamily,
                color: AppColors.cFCFAFE,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.primaryFontFamily,
                color: AppColors.cFCFAFE.withValues(alpha: 0.60),
                fontSize: 15,
                height: 1.40,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: _resolvedConfirmGradient,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: TextButton(
                  onPressed: onConfirm,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.cFCFAFE,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: AppTypography.displayFontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                  child: Text(confirmLabel),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: onCancel ?? () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.cFCFAFE.withValues(alpha: 0.70),
                textStyle: const TextStyle(
                  fontFamily: AppTypography.primaryFontFamily,
                  fontSize: 15,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.cFCFAFE,
                ),
              ),
              child: Text(cancelLabel),
            ),
          ],
        ),
      ),
    );
  }
}
