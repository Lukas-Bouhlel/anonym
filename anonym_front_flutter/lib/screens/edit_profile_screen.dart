import 'dart:io';
import 'dart:math' as math;

import 'package:file_selector/file_selector.dart' as fs;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/app_controller.dart';
import '../providers/auth_controller.dart';
import '../theme.dart';
import '../widgets/app_remote_image.dart';
import '../widgets/chrome/moji_back_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();

  bool _didInit = false;
  bool _isSaving = false;
  bool _deleteAvatar = false;
  String _initialUsername = '';
  String _initialEmail = '';
  String? _initialBio;
  bool _allowNonFriendDms = true;

  String? _pendingAvatarPath;
  Uint8List? _pendingAvatarBytes;
  String? _pendingAvatarFileName;

  bool get _isDesktopOrWebAvatarPicker =>
      kIsWeb || defaultTargetPlatform == TargetPlatform.windows;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    final user = context.read<AuthController>().user;
    _initialUsername = user?.username ?? '';
    _initialEmail = user?.email ?? '';
    _initialBio = user?.bio;
    _allowNonFriendDms = user?.allowNonFriendDms ?? true;
    _nameController.text = _initialUsername;
    _emailController.text = _initialEmail;
    _bioController.text = _initialBio ?? '';
    _didInit = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  EdgeInsets _bottomActionPadding(BuildContext context) {
    const visualGap = 16.0;
    final mediaQuery = MediaQuery.of(context);
    final systemBottom = math.max(
      mediaQuery.padding.bottom,
      mediaQuery.viewPadding.bottom,
    );
    final bottom = Theme.of(context).platform == TargetPlatform.android
        ? (systemBottom > 0 ? systemBottom + visualGap : visualGap * 2)
        : math.max(systemBottom, visualGap);
    return EdgeInsets.only(bottom: bottom);
  }

  Future<void> _showPhotoBottomSheet() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        decoration: BoxDecoration(
          gradient: AppGradients.gB1BCFBTo393566,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.cFCFAFE.withValues(alpha: 0.35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isDesktopOrWebAvatarPicker)
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.whiteColor,
                ),
                title: const Text(
                  'Changer d\'avatar',
                  style: TextStyle(color: AppColors.whiteColor),
                ),
                onTap: () => Navigator.of(context).pop('gallery'),
              )
            else ...[
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.whiteColor,
                ),
                title: const Text(
                  'Galerie',
                  style: TextStyle(color: AppColors.whiteColor),
                ),
                onTap: () => Navigator.of(context).pop('gallery'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.whiteColor,
                ),
                title: const Text(
                  'Camera',
                  style: TextStyle(color: AppColors.whiteColor),
                ),
                onTap: () => Navigator.of(context).pop('camera'),
              ),
            ],
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: AppColors.whiteColor,
              ),
              title: const Text(
                'Supprimer la photo de profil',
                style: TextStyle(color: AppColors.whiteColor),
              ),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;

    if (action == 'gallery') {
      if (_isDesktopOrWebAvatarPicker) {
        await _pickDesktopOrWebAvatar();
      } else {
        await _pickAvatarMobile(ImageSource.gallery);
      }
      return;
    }
    if (action == 'camera') {
      await _pickAvatarMobile(ImageSource.camera);
      return;
    }
    if (action == 'delete') {
      setState(() {
        _deleteAvatar = true;
        _pendingAvatarPath = null;
        _pendingAvatarBytes = null;
        _pendingAvatarFileName = null;
      });
    }
  }

  Future<void> _pickDesktopOrWebAvatar() async {
    final file = await fs.openFile(
      acceptedTypeGroups: const [
        fs.XTypeGroup(
          label: 'images',
          extensions: ['jpg', 'jpeg', 'png', 'gif', 'svg'],
        ),
      ],
    );
    if (!mounted || file == null) return;

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      if (!mounted || bytes.isEmpty) return;
      setState(() {
        _deleteAvatar = false;
        _pendingAvatarPath = null;
        _pendingAvatarBytes = bytes;
        _pendingAvatarFileName = file.name;
      });
      return;
    }

    setState(() {
      _deleteAvatar = false;
      _pendingAvatarPath = file.path;
      _pendingAvatarBytes = null;
      _pendingAvatarFileName = file.name;
    });
  }

  Future<void> _pickAvatarMobile(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 1600,
      );
      if (!mounted || picked == null) return;
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        if (!mounted || bytes.isEmpty) return;
        setState(() {
          _deleteAvatar = false;
          _pendingAvatarPath = null;
          _pendingAvatarBytes = bytes;
          _pendingAvatarFileName = picked.name;
        });
        return;
      }
      setState(() {
        _deleteAvatar = false;
        _pendingAvatarPath = picked.path;
        _pendingAvatarBytes = null;
        _pendingAvatarFileName = picked.name;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de recuperer la photo: $e')),
      );
    }
  }

  Widget _buildProfileImage(String? remoteUrl) {
    if (_pendingAvatarBytes != null && _pendingAvatarBytes!.isNotEmpty) {
      return Image.memory(
        _pendingAvatarBytes!,
        width: 140,
        height: 140,
        fit: BoxFit.cover,
      );
    }
    final localPath = (_pendingAvatarPath ?? '').trim();
    if (localPath.isNotEmpty) {
      final file = File(localPath);
      if (file.existsSync()) {
        return Image.file(file, width: 140, height: 140, fit: BoxFit.cover);
      }
    }
    return AppRemoteImage(
      url: _deleteAvatar ? null : remoteUrl,
      width: 140,
      height: 140,
      fallbackIcon: Icons.person,
    );
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    final rawUsername = _nameController.text.trim();
    final rawEmail = _emailController.text.trim();
    final rawBio = _bioController.text.trim();
    if (rawUsername.isEmpty || rawEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username et email sont obligatoires.')),
      );
      return;
    }
    final username = rawUsername;
    final email = rawEmail;
    final String? bio = rawBio.isEmpty ? null : rawBio;

    final app = context.read<AppController>();
    setState(() => _isSaving = true);
    await app.updateProfile(
      username: username,
      email: email,
      bio: bio,
      allowNonFriendDms: _allowNonFriendDms,
      avatarFilePath: _pendingAvatarPath,
      avatarBytes: _pendingAvatarBytes,
      avatarFileName: _pendingAvatarFileName,
      deleteAvatar: _deleteAvatar,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (app.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(app.errorMessage!)));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profil modifie')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.gB1BCFBTo393566),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Row(
                  children: [
                    const MojiBackButton(),
                    const SizedBox(width: 20),
                    Text(
                      'Modifier le profil',
                      style: textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: _showPhotoBottomSheet,
                    child: ClipOval(child: _buildProfileImage(user?.avatar)),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _InlineField(
                          label: 'Username',
                          controller: _nameController,
                          hintText: _initialUsername.isEmpty
                              ? 'Username'
                              : _initialUsername,
                        ),
                        const SizedBox(height: 12),
                        _InlineField(
                          label: 'Email',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          hintText: _initialEmail.isEmpty
                              ? 'Email'
                              : _initialEmail,
                        ),
                        const SizedBox(height: 12),
                        _ToggleField(
                          label: 'Autoriser les DM des non-amis',
                          value: _allowNonFriendDms,
                          helper: _allowNonFriendDms
                              ? 'Tout utilisateur peut vous envoyer un DM.'
                              : 'Seuls vos amis actifs peuvent vous envoyer un DM.',
                          onChanged: (value) {
                            setState(() => _allowNonFriendDms = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        _InlineField(
                          label: 'Bio',
                          controller: _bioController,
                          maxLines: 4,
                          hintText: (_initialBio ?? '').trim().isEmpty
                              ? 'Ton hobby du moment ?'
                              : _initialBio!,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: _bottomActionPadding(context),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        backgroundColor: AppColors.whiteColor,
                        foregroundColor: AppColors.c393566,
                        textStyle: const TextStyle(
                          fontFamily: AppTypography.primaryFontFamily,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      child: Text(_isSaving ? 'Enregistrement...' : 'Terminer'),
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
