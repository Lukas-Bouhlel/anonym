import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme.dart';

/// Ecran de chargement affiché pendant le bootstrap applicatif.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = Tween<double>(begin: 0.9, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    final glow = Tween<double>(begin: 0.18, end: 0.46).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    final drift = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.gB1BCFBTo393566),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Transform.translate(
                offset: Offset(0, drift.value),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 138,
                      height: 138,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.whiteColor.withValues(
                          alpha: glow.value * 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.whiteColor.withValues(
                              alpha: glow.value,
                            ),
                            blurRadius: 38,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    Transform.scale(
                      scale: scale.value,
                      child: SvgPicture.asset(
                        'assets/icons/anonym_logo.svg',
                        width: 86,
                        height: 86,
                        colorFilter: const ColorFilter.mode(
                          AppColors.whiteColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
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
