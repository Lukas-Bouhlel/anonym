import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart' as fs;
import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';

import '../providers/app_providers.dart';
import '../theme.dart';
import '../widgets/navigation/anonym_glass_bottom_nav.dart';
import 'channels_screen.dart';
import 'friends_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';


part '../widgets/app_shell_screen_widgets.dart';

/// Écran shell principal qui orchestre la navigation interne authentifiée.
class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  late int _tabIndex;

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTabIndex.clamp(0, 3);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = context.read<AppProvider>();
      if (!app.isBootstrapping &&
          app.channels.isEmpty &&
          app.friends.isEmpty &&
          app.shopItems.isEmpty) {
        app.refreshAll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        if (app.selectedChannel != null && _tabIndex != 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _tabIndex = 1);
          });
        }
        final isChatOpen = _tabIndex == 1 && app.selectedChannel != null;
        return Scaffold(
          extendBody: true,
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppGradients.gB1BCFBTo393566,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(child: _buildCurrentTab()),
                if (app.isBootstrapping || app.isSubmitting)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: LinearProgressIndicator(
                        minHeight: 2,
                        backgroundColor: Colors.transparent,
                        color: AppColors.cFCFAFE.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          bottomNavigationBar: isChatOpen
              ? null
              : AnonymGlassBottomNav(
                  currentIndex: _tabIndex,
                  onTap: (index) => setState(() => _tabIndex = index),
                  onCenterTap: () => _showQuickActions(context),
                ),
        );
      },
    );
  }

  Widget _buildCurrentTab() {
    switch (_tabIndex) {
      case 0:
        return const HomeScreen();
      case 1:
        return const ChannelsScreen();
      case 2:
        return const FriendsScreen();
      case 3:
        return const ProfileScreen();
      default:
        return const HomeScreen();
    }
  }

  Future<void> _showQuickActions(BuildContext context) async {
    final app = context.read<AppProvider>();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return _SheetShell(
          title: 'Créer ton groupe',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Ton groupe est l'endroit où tu retrouves tes amis. Crée le tien et lance une discussion.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.cFCFAFE, fontSize: 13),
              ),
              const SizedBox(height: 14),
              _ActionRow(
                icon: Icons.public_rounded,
                label: 'Créer un groupe',
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _showCreateGroupTypeSheet(context, app);
                  if (!mounted) return;
                  setState(() => _tabIndex = 1);
                },
              ),
              const SizedBox(height: 8),
              _ActionRow(
                icon: Icons.login_rounded,
                label: 'Rejoindre un groupe',
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  if (!context.mounted) return;
                  await _openJoinPublicDirectoryScreen(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCreateGroupTypeSheet(
    BuildContext context,
    AppProvider app,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return _SheetShell(
          title: 'Dis-nous en plus sur ton groupe',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Est-il destiné à quelques amis ou à une communauté plus large ?',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.cFCFAFE, fontSize: 13),
              ),
              const SizedBox(height: 14),
              _ActionRow(
                icon: Icons.groups_rounded,
                label: 'Pour un club ou une communauté',
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _showCreateGroupDetailsSheet(
                    context,
                    app,
                    visibility: 'PUBLIC',
                  );
                },
              ),
              const SizedBox(height: 8),
              _ActionRow(
                icon: Icons.lock_outline_rounded,
                label: 'Pour mes amis et moi',
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _showCreateGroupDetailsSheet(
                    context,
                    app,
                    visibility: 'PRIVATE',
                  );
                },
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      color: AppColors.cFCFAFE,
                      fontSize: 15,
                    ),
                    children: [
                      const TextSpan(text: 'Tu ne sais pas ? Tu peux '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: () async {
                            Navigator.of(sheetContext).pop();
                            await _showCreateGroupDetailsSheet(
                              context,
                              app,
                              visibility: 'PRIVATE',
                            );
                          },
                          child: const Text(
                            'ignorer cette question',
                            style: TextStyle(
                              color: AppColors.cCFFFDD,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: ' pour l\'instant.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCreateGroupDetailsSheet(
    BuildContext context,
    AppProvider app, {
    required String visibility,
  }) async {
    String name = '';
    String? imageFilePath;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return _SheetShell(
              title: 'Personnalise ton groupe',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Center(
                    child: _FieldLabel(
                      'Donne une personnalité à ton nouveau groupe en choisissant un nom et une icône. Tu pourras toujours les modifier plus tard.',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        final file = await fs.openFile(
                          acceptedTypeGroups: const [
                            fs.XTypeGroup(
                              label: 'images',
                              extensions: ['jpg', 'jpeg', 'png', 'webp', 'svg'],
                            ),
                          ],
                        );
                        if (file == null) return;
                        final nextPath = file.path;
                        if (nextPath.isEmpty) return;
                        setModalState(() {
                          imageFilePath = nextPath;
                        });
                      },
                      child: SizedBox(
                        width: 120,
                        height: 120,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.cFCFAFE.withValues(
                                    alpha: 0.55,
                                  ),
                                  width: 2,
                                ),
                                color: AppColors.cFCFAFE.withValues(
                                  alpha: 0.06,
                                ),
                              ),
                              child: imageFilePath != null
                                  ? ClipOval(
                                      child: Image.file(
                                        File(imageFilePath!),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.camera_alt_rounded,
                                          color: AppColors.cFCFAFE,
                                          size: 28,
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'UPLOAD',
                                          style: TextStyle(
                                            color: AppColors.cFCFAFE,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.secondary,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: AppColors.cFCFAFE,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      _FieldLabel('Nom du groupe'),
                      Text(
                        ' *',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _SheetTextField(
                    hint: '',
                    onChanged: (v) => setModalState(() => name = v),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          color: AppColors.cFCFAFE,
                          fontSize: 13,
                        ),
                        children: [
                          const TextSpan(
                            text: 'En créant un serveur, tu acceptes la ',
                          ),
                          TextSpan(
                            text:
                                'Charte d\'utilisation de la communauté Anonym',
                            style: const TextStyle(
                              color: AppColors.cCFFFDD,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: TapGestureRecognizer()..onTap = () {},
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      SizedBox(
                        height: 48,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.cFCFAFE,
                            overlayColor: Colors.transparent,
                            textStyle: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            _showCreateGroupTypeSheet(context, app);
                          },
                          child: const Text('Retour'),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 100,
                        child: SizedBox(
                          height: 48,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: name.trim().isEmpty
                                  ? const Color(
                                      0xFF6C63FF,
                                    ).withValues(alpha: 0.40)
                                  : const Color(0xFF6C63FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: TextButton(
                              onPressed: name.trim().isEmpty
                                  ? null
                                  : () async {
                                      await app.createGroupChannel(
                                        name: name.trim(),
                                        description: '',
                                        visibility: visibility,
                                        imageFilePath: imageFilePath,
                                      );
                                      if (!sheetContext.mounted) return;
                                      Navigator.of(sheetContext).pop();
                                    },
                              style: TextButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                foregroundColor: AppColors.cFCFAFE,
                                disabledForegroundColor: AppColors.cFCFAFE
                                    .withValues(alpha: 0.90),
                                textStyle: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: const Text('Créer'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openJoinPublicDirectoryScreen(BuildContext context) async {
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const PublicConversationsScreen(),
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
