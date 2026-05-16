import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../providers/app_controller.dart';
import '../providers/auth_controller.dart';
import '../theme.dart';
import '../widgets/app_remote_image.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;
    final t = Theme.of(context).textTheme;

    return Consumer<AppController>(
      builder: (context, app, _) {
        final activeItem = app.inventoryItems
            .where((item) => item.active)
            .toList(growable: false);
        String activeDecoration = '';
        if (activeItem.isNotEmpty) {
          final firstActive = activeItem.first;
          final fromInventory = (firstActive.shop?.content ?? '').trim();
          if (fromInventory.isNotEmpty) {
            activeDecoration = fromInventory;
          } else {
            final fromShop = app.shopItems
                .where((shop) => shop.articleId == firstActive.articleId)
                .map((shop) => shop.content.trim())
                .firstWhere((url) => url.isNotEmpty, orElse: () => '');
            activeDecoration = fromShop;
          }
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              auth.reloadCurrentUser(),
              app.refreshInventory(),
              app.refreshInvoices(),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 140),
            children: [
              SafeArea(
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppGradients.gB1BCFBTo393566,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppColors.cFCFAFE.withValues(alpha: 0.38),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 58,
                            height: 58,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipOval(
                                  child: AppRemoteImage(
                                    url: user?.avatar,
                                    width: 58,
                                    height: 58,
                                    fallbackIcon: Icons.person,
                                  ),
                                ),
                                if (activeDecoration.isNotEmpty)
                                  AppRemoteImage(
                                    url: activeDecoration,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.contain,
                                    fallbackIcon: Icons.blur_on_rounded,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.username ?? '',
                                  style: t.displayMedium?.copyWith(height: 0.9),
                                ),
                                Text(
                                  (user?.bio ?? '').trim().isEmpty
                                      ? ''
                                      : user!.bio!,
                                  style: const TextStyle(
                                    color: AppColors.cDBE7FE,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            ),
                            icon: const Icon(
                              Icons.tune,
                              color: AppColors.cFCFAFE,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const EditProfileScreen(),
                                ),
                              ),
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: AppGradients.gB1BCFBTo393566,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: AppColors.cFCFAFE.withValues(
                                      alpha: 0.55,
                                    ),
                                    width: 1.4,
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Modifier le profil',
                                        style: TextStyle(
                                          color: AppColors.cFCFAFE,
                                          fontFamily:
                                              AppTypography.primaryFontFamily,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SvgPicture.asset(
                                        'assets/icons/edit_profil_icon.svg',
                                        width: 18,
                                        height: 18,
                                        colorFilter: const ColorFilter.mode(
                                          AppColors.cFCFAFE,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _showShareModal(
                              context,
                              username: user?.username ?? 'Utilisateur',
                            ),
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: AppGradients.gB1BCFBTo393566,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(18),
                                ),
                                border: Border.all(
                                  color: AppColors.cFCFAFE.withValues(
                                    alpha: 0.55,
                                  ),
                                  width: 1.4,
                                ),
                              ),
                              child: Center(
                                child: SvgPicture.asset(
                                  'assets/icons/share.svg',
                                  width: 16,
                                  height: 16,
                                  colorFilter: const ColorFilter.mode(
                                    AppColors.cFCFAFE,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    'Progression',
                    style: t.displaySmall?.copyWith(height: 0.9),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppGradients.gD09EFEToD0BAFF,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'LVL 45',
                      style: TextStyle(
                        color: AppColors.cFCFAFE,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cB1BCFB.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.cFCFAFE.withValues(alpha: 0.28),
                  ),
                ),
                child: Row(
                  children: [
                    ...List.generate(
                      10,
                      (index) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          height: 8,
                          decoration: BoxDecoration(
                            color: index < 5
                                ? AppColors.cCFFFDD
                                : AppColors.cFCFAFE,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.cDBE7FE,
                      child: Text(
                        '46',
                        style: TextStyle(color: AppColors.c393566),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.cCCD4F4,
                      child: Text(
                        '47',
                        style: TextStyle(color: AppColors.c393566),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Reputation', style: t.displaySmall?.copyWith(height: 0.9)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cB1BCFB.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.cFCFAFE.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: AppColors.cCFFFDD),
                        SizedBox(width: 8),
                        Text(
                          'Niveau 45',
                          style: TextStyle(
                            color: AppColors.cFCFAFE,
                            fontSize: 32,
                            height: 0.9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.more_vert, color: AppColors.cFCFAFE),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Graphique de la chaine de reputation',
                      style: TextStyle(color: AppColors.cDBE7FE),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: CustomPaint(
                        painter: _ReputationLinePainter(),
                        size: const Size(double.infinity, 120),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showShareModal(
    BuildContext context, {
    required String username,
  }) async {
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) =>
            ShareProfileScreen(username: username),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final offset =
              Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );
          return SlideTransition(position: offset, child: child);
        },
      ),
    );
  }
}

class ShareProfileScreen extends StatelessWidget {
  const ShareProfileScreen({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final profileLink = 'https://anonym.app/u/$username';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.gB1BCFBTo393566),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(14),
                    child: Ink(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.cB1BCFB.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.cFCFAFE.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: AppColors.cFCFAFE,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  username,
                  style: t.displayMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 18),
                Container(
                  width: 232,
                  height: 232,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cFCFAFE,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: QrImageView(
                    data: profileLink,
                    version: QrVersions.auto,
                    gapless: true,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.c121212,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.c121212,
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Partage bientot disponible.'),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.cFCFAFE,
                      foregroundColor: AppColors.c121212,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: AppGradients.gCFFFDDToFCFAFE,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Partager',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontFamily: AppTypography.primaryFontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: profileLink));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lien copie.')),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.cFCFAFE,
                      foregroundColor: AppColors.c121212,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: AppGradients.gB1BCFBTo393566,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.cFCFAFE.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Copier le lien',
                          style: TextStyle(
                            color: AppColors.cFCFAFE,
                            fontFamily: AppTypography.primaryFontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Annuler',
                    style: TextStyle(
                      color: AppColors.cFCFAFE,
                      fontFamily: AppTypography.primaryFontFamily,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReputationLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final axis = Paint()
      ..color = AppColors.cFCFAFE.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = size.height * (i + 1) / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), axis);
    }

    final path = Path();
    final points = [
      Offset(0, size.height * 0.75),
      Offset(size.width * 0.1, size.height * 0.55),
      Offset(size.width * 0.22, size.height * 0.62),
      Offset(size.width * 0.32, size.height * 0.34),
      Offset(size.width * 0.45, size.height * 0.64),
      Offset(size.width * 0.58, size.height * 0.48),
      Offset(size.width * 0.73, size.height * 0.7),
      Offset(size.width * 0.86, size.height * 0.46),
      Offset(size.width, size.height * 0.78),
    ];
    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final control = Offset((previous.dx + current.dx) / 2, previous.dy);
      final control2 = Offset((previous.dx + current.dx) / 2, current.dy);
      path.cubicTo(
        control.dx,
        control.dy,
        control2.dx,
        control2.dy,
        current.dx,
        current.dy,
      );
    }

    final stroke = Paint()
      ..color = AppColors.cCFFFDD
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
