part of '../screens/edit_profile_screen.dart';

class _InlineField extends StatelessWidget {
  const _InlineField({
    required this.label,
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: BoxDecoration(
        gradient: AppGradients.gB1BCFBTo393566,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.cFCFAFE.withValues(alpha: 0.35),
          width: 1.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.titleSmall?.copyWith(
              color: AppColors.whiteColor,
              fontFamily: AppTypography.displayFontFamily,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: const InputDecorationTheme(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              keyboardType: keyboardType,
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.whiteColor,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: AppColors.whiteColor,
              decoration: InputDecoration.collapsed(
                hintText: hintText,
                hintStyle: textTheme.bodyLarge?.copyWith(
                  color: AppColors.whiteColor.withValues(alpha: 0.35),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleField extends StatelessWidget {
  const _ToggleField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.helper,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
      decoration: BoxDecoration(
        gradient: AppGradients.gB1BCFBTo393566,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.cFCFAFE.withValues(alpha: 0.35),
          width: 1.1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.whiteColor,
                    fontFamily: AppTypography.displayFontFamily,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (helper != null && helper!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    helper!,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.cDBE7FE,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.c393566,
            activeTrackColor: AppColors.cCFFFDD,
            inactiveThumbColor: AppColors.cFCFAFE,
            inactiveTrackColor: AppColors.cFCFAFE.withValues(alpha: 0.25),
            trackOutlineColor: WidgetStateProperty.resolveWith((states) {
              return AppColors.cFCFAFE.withValues(alpha: 0.25);
            }),
            trackOutlineWidth: WidgetStateProperty.resolveWith((states) {
              return 1.0;
            }),
          ),
        ],
      ),
    );
  }
}
