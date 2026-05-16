import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme.dart';
import '../utils/media_url.dart';

class AppRemoteImage extends StatelessWidget {
  const AppRemoteImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = Icons.image_not_supported,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final normalized = MediaUrl.nullable(url);
    if (normalized == null) {
      return _fallback();
    }

    final image = _looksLikeSvg(normalized)
        ? SvgPicture.network(
            normalized,
            width: width,
            height: height,
            fit: fit,
            placeholderBuilder: (context) => _loading(),
          )
        : Image.network(
            normalized,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              // Some backends serve SVG avatars with non-standard extensions.
              return SvgPicture.network(
                normalized,
                width: width,
                height: height,
                fit: fit,
                placeholderBuilder: (context) => _loading(),
              );
            },
          );

    final clipped = borderRadius == null
        ? image
        : ClipRRect(borderRadius: borderRadius!, child: image);

    return clipped;
  }

  bool _looksLikeSvg(String value) {
    final lower = value.toLowerCase();
    return lower.endsWith('.svg') || lower.contains('.svg?');
  }

  Widget _loading() {
    return SizedBox(
      width: width,
      height: height,
      child: const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _fallback() {
    return SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: AppColors.surfaceSoft,
        child: Icon(fallbackIcon, color: AppColors.textSecondary),
      ),
    );
  }
}
