import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart' as fs;
import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';

import '../providers/app_controller.dart';
import '../theme.dart';
import '../widgets/chrome/moji_glass_bottom_nav.dart';
import 'channels_screen.dart';
import 'friends_screen.dart';
import 'home_screen.dart';
import 'placeholder_screen.dart';
import 'profile_screen.dart';

class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key});

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = context.read<AppController>();
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
    return Consumer<AppController>(
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
              : MojiGlassBottomNav(
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
    final app = context.read<AppController>();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return _SheetShell(
          title: 'Creer ton groupe',
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
                label: 'Creer un groupe',
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
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PlaceholderScreen(
                        title: 'Rejoindre un groupe',
                        description:
                            'Ecran dedie a finaliser: recherche, liste des groupes publics et demande d acces privee.',
                      ),
                    ),
                  );
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
    AppController app,
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
                label: 'Pour un club ou une communaute',
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
    AppController app, {
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
                                'Charte d\'Utilisation de la Communauté Anonym',
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
                              child: const Text('Creer'),
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
}

class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
        padding: EdgeInsets.fromLTRB(
          16,
          10,
          16,
          16 + mediaQuery.padding.bottom,
        ),
        decoration: BoxDecoration(
          gradient: AppGradients.gB1BCFBTo393566,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.cFCFAFE.withValues(alpha: 0.28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.cFCFAFE.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: AppTypography.displayFontFamily,
                  color: AppColors.cFCFAFE,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
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
                  fontWeight: FontWeight.w600,
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.value);
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      textAlign: TextAlign.center,
      style: const TextStyle(color: AppColors.cFCFAFE, fontSize: 13),
    );
  }
}

class _SheetTextField extends StatelessWidget {
  const _SheetTextField({required this.hint, required this.onChanged});

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cFCFAFE.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cFCFAFE.withValues(alpha: 0.18)),
      ),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.cFCFAFE),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.cFCFAFE.withValues(alpha: 0.4)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 11,
          ),
        ),
      ),
    );
  }
}
