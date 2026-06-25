part of '../screens/payment_success_screen.dart';

class _LogoMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/icons/anonym_logo.svg',
          height: 40,
          colorFilter: const ColorFilter.mode(
            AppColors.whiteColor,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'nonym',
          style: TextStyle(
            color: AppColors.whiteColor,
            fontFamily: AppTypography.displayFontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 48,
            height: 0.95,
            letterSpacing: -0.8,
          ),
        ),
      ],
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({
    required this.content,
    required this.articleImageUrl,
    required this.amount,
    required this.date,
    required this.onBack,
  });

  final String content;
  final String? articleImageUrl;
  final int? amount;
  final DateTime? date;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 18),
          decoration: BoxDecoration(
            gradient: AppGradients.gB1BCFBTo393566,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border(
              top: BorderSide(color: AppColors.cFCFAFE.withValues(alpha: 0.28)),
              left: BorderSide(
                color: AppColors.cFCFAFE.withValues(alpha: 0.28),
              ),
              right: BorderSide(
                color: AppColors.cFCFAFE.withValues(alpha: 0.28),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.cFCFAFE.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 28),
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) =>
                    AppGradients.gCFFFDDToFCFAFE.createShader(bounds),
                child: Text(
                  'Super !',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    fontFamily: AppTypography.primaryFontFamily,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Paiement confirmé',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.cFCFAFE,
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  fontFamily: AppTypography.displayFontFamily,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Merci pour votre achat!',
                style: TextStyle(
                  color: AppColors.cFCFAFE.withValues(alpha: 0.82),
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 10),
              Divider(
                color: AppColors.cFCFAFE.withValues(alpha: 0.2),
                thickness: 1,
                height: 1,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Votre résumé',
                        style: TextStyle(
                          color: AppColors.cFCFAFE.withValues(alpha: 0.75),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: AppGradients.gB1BCFBTo393566,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.cFCFAFE.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AppRemoteImage(
                              url: articleImageUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              fallbackIcon: Icons.image_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              content.trim().isEmpty ? 'Article' : content,
                              textAlign: TextAlign.left,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.cFCFAFE,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Total',
                      style: TextStyle(
                        color: AppColors.cFCFAFE.withValues(alpha: 0.82),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) =>
                          AppGradients.gCFFFDDToFCFAFE.createShader(bounds),
                      child: Text(
                        '${amount ?? '-'} EUR',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Le ${AppDateFormat.shortDate(date)}',
                      style: TextStyle(
                        color: AppColors.cFCFAFE.withValues(alpha: 0.82),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppGradients.gB1BCFBTo393566,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.cFCFAFE.withValues(alpha: 0.2),
                          ),
                        ),
                        child: TextButton(
                          onPressed: onBack,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.whiteColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                          child: const Text(
                            'Retour sur Anonym',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -34,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                gradient: AppGradients.gCFFFDDToFCFAFE,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: AppColors.primary,
                size: 36,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
      decoration: BoxDecoration(
        gradient: AppGradients.gB1BCFBTo393566,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cFCFAFE.withValues(alpha: 0.28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.cFCFAFE.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const Icon(Icons.error_rounded, color: AppColors.danger, size: 40),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.cFCFAFE),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onBack,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.cFCFAFE.withValues(alpha: 0.13),
              foregroundColor: AppColors.cFCFAFE,
              side: BorderSide(color: AppColors.cFCFAFE.withValues(alpha: 0.2)),
            ),
            child: const Text('Retour sur Anonym'),
          ),
        ],
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress});

  final double progress;

  static const List<Color> _palette = [
    Color(0xFFCFFFDD),
    Color(0xFF393566),
    Color(0xFFB1BCFB),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    const count = 30;

    for (var i = 0; i < count; i++) {
      final seed = i + 1.0;
      final startX = (math.sin(seed * 3.47) * 0.5 + 0.5) * size.width;
      final spread = ((i % 3) - 1) * 42.0;
      final t = ((progress + (i * 0.037)) % 1.0);
      final y = (t * t) * size.height;
      final x = startX + spread * t + math.sin(t * 8 + seed) * 12;
      final rot = (t * 8) + seed;
      final particleSize = 6 + (i % 4) * 2.0;

      paint.color = _palette[i % _palette.length].withValues(alpha: 0.95);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);

      if (i % 2 == 0) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: particleSize * 0.8,
            height: particleSize * 1.5,
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, particleSize * 0.45, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
