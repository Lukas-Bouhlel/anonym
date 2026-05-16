import 'dart:io';

import 'package:file_selector/file_selector.dart' as fs;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/channel_model.dart';
import '../providers/app_controller.dart';
import '../providers/auth_controller.dart';
import '../theme.dart';
import '../widgets/app_remote_image.dart';
import '../widgets/chrome/moji_back_button.dart';
import '../widgets/modals/moji_confirm_modal.dart';

class GroupSettingsScreen extends StatefulWidget {
  const GroupSettingsScreen({super.key, required this.channel});

  final ChannelModel channel;

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late String _visibility;
  String? _imagePath;
  bool _removeCurrentIcon = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.channel.name);
    _descriptionController = TextEditingController(
      text: widget.channel.description ?? '',
    );
    _visibility = widget.channel.visibility.trim().toUpperCase() == 'PUBLIC'
        ? 'PUBLIC'
        : 'PRIVATE';
    _nameController.addListener(_refresh);
    _descriptionController.addListener(_refresh);
  }

  @override
  void dispose() {
    _nameController.removeListener(_refresh);
    _descriptionController.removeListener(_refresh);
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final isPrivate = _visibility == 'PRIVATE';
    final currentUserId = context.watch<AuthController>().user?.id;
    final isCreator = currentUserId != null && currentUserId == widget.channel.createdBy;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.gB1BCFBTo393566),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    MojiBackButton(onTap: () => Navigator.of(context).pop()),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Modifier le groupe',
                        style: TextStyle(
                          fontFamily: AppTypography.displayFontFamily,
                          color: AppColors.cFCFAFE,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Personnalise la façon dont ton groupe apparaît dans les invitations.",
                        style: TextStyle(
                          color: AppColors.cFCFAFE.withValues(alpha: 0.65),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const _SectionLabel('Nom du groupe'),
                      const SizedBox(height: 8),
                      _GlassTextField(
                        controller: _nameController,
                        hint: '',
                      ),
                      const SizedBox(height: 20),
                      const _SectionLabel('Description'),
                      const SizedBox(height: 8),
                      _GlassTextField(
                        controller: _descriptionController,
                        hint: '',
                        maxLines: 3,
                      ),
                       const SizedBox(height: 28),
                       const _SectionLabel('Icône'),
                      const SizedBox(height: 4),
                      Text(
                        "Nous recommandons une taille d'image d'au moins 512 x 512.",
                        style: TextStyle(
                          color: AppColors.cFCFAFE.withValues(alpha: 0.55),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _pickIcon,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF6C63FF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text(
                                "Changer l'icône du groupe",
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _imagePath != null ||
                                      ((widget.channel.coverImage ?? '').isNotEmpty &&
                                          !_removeCurrentIcon)
                                  ? () => setState(() {
                                      _imagePath = null;
                                      _removeCurrentIcon = true;
                                    })
                                  : null,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.whiteColor,
                                side: BorderSide(
                                  color: AppColors.cFCFAFE.withValues(alpha: 0.10),
                                ),
                                backgroundColor: AppColors.danger,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text(
                                "Supprimer l'icône",
                                style: TextStyle(
                                  color: AppColors.whiteColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      const _SectionLabel('Visibilité'),
                      const SizedBox(height: 12),
                      _PrivacyToggleCard(
                        isPrivate: isPrivate,
                        onChanged: (value) => setState(
                          () => _visibility = value ? 'PRIVATE' : 'PUBLIC',
                        ),
                      ),
                      const SizedBox(height: 24),
                      const _SectionLabel("Aperçu de l'invitation"),
                      const SizedBox(height: 10),
                      _InvitePreviewCard(
                        isPrivate: isPrivate,
                        serverName: _nameController.text.trim(),
                        description: _descriptionController.text.trim(),
                        profileImageUrl: _removeCurrentIcon
                            ? null
                            : widget.channel.coverImage,
                        localProfileImagePath: _imagePath,
                      ),
                      const SizedBox(height: 36),
                      _GradientButton(
                        label: 'Enregistrer les modifications',
                        loading: app.isSubmitting,
                        onPressed: app.isSubmitting ? null : _save,
                      ),
                      const SizedBox(height: 12),
                      _DangerButton(
                        label: isCreator ? 'Supprimer le groupe' : 'Quitter le groupe',
                        icon: Icons.exit_to_app_rounded,
                        onPressed: () => _handleLeaveOrDelete(isCreator),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickIcon() async {
    final file = await fs.openFile(
      acceptedTypeGroups: const [
        fs.XTypeGroup(label: 'images', extensions: ['jpg', 'jpeg', 'png', 'webp']),
      ],
    );
    if (file == null || file.path.isEmpty) return;
    setState(() {
      _imagePath = file.path;
      _removeCurrentIcon = false;
    });
  }

  Future<void> _save() async {
    await context.read<AppController>().updateSelectedGroup(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      visibility: _visibility,
      imageFilePath: _imagePath,
    );
    if (!mounted) return;
    final error = context.read<AppController>().errorMessage;
    if (error != null && error.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _handleLeaveOrDelete(bool isCreator) async {
    final app = context.read<AppController>();
    if (isCreator) {
      final confirmed = await _showDeleteGroupConfirmModal();
      if (confirmed != true) return;
      await app.deleteSelectedChannel();
    } else {
      await app.leaveSelectedChannel();
    }
    if (!mounted) return;
    final error = app.errorMessage;
    if (error != null && error.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(context).pop();
  }

  Future<bool?> _showDeleteGroupConfirmModal() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return MojiConfirmModal(
          title: 'Supprimer ce groupe ?',
          description:
              "Cette action est définitive. Tous les messages et accès au groupe seront supprimés.",
          confirmLabel: 'Supprimer le groupe',
          onConfirm: () => Navigator.of(context).pop(true),
          onCancel: () => Navigator.of(context).pop(false),
        );
      },
    );
  }
}

class _PrivacyToggleCard extends StatelessWidget {
  const _PrivacyToggleCard({
    required this.isPrivate,
    required this.onChanged,
  });
  final bool isPrivate;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.cFCFAFE.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cFCFAFE.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPrivate ? 'Profil privé' : 'Profil public',
                  style: const TextStyle(
                    color: AppColors.cFCFAFE,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isPrivate
                      ? "Seuls les membres du groupe peuvent voir le contenu du profil. Les non-membres ne peuvent pas accéder sans invitation."
                      : "Le groupe est visible publiquement. N'importe qui peut rejoindre via invitation.",
                  style: TextStyle(
                    color: AppColors.cFCFAFE.withValues(alpha: 0.65),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: isPrivate,
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
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _InvitePreviewCard extends StatelessWidget {
  const _InvitePreviewCard({
    required this.isPrivate,
    required this.serverName,
    required this.description,
    this.profileImageUrl,
    this.localProfileImagePath,
  });
  final bool isPrivate;
  final String serverName;
  final String description;
  final String? profileImageUrl;
  final String? localProfileImagePath;

  @override
  Widget build(BuildContext context) {
    final title = serverName.isEmpty
        ? (isPrivate ? 'Groupe privé' : 'Groupe public')
        : serverName;
    final subtitle = description.isEmpty
        ? (isPrivate
              ? "Le groupe a limité l'accès à ce profil."
              : "Le groupe est visible dans les invitations.")
        : description;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cFCFAFE.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cFCFAFE.withValues(alpha: 0.16)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.c393566,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.cFCFAFE.withValues(alpha: 0.2),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildAvatar(),
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.c393566,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.cFCFAFE.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Icon(
                    isPrivate ? Icons.lock_rounded : Icons.public_rounded,
                    size: 12,
                    color: AppColors.cFCFAFE,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.cFCFAFE,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.cFCFAFE.withValues(alpha: 0.60),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (localProfileImagePath != null && localProfileImagePath!.isNotEmpty) {
      return Image.file(File(localProfileImagePath!), fit: BoxFit.cover);
    }
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      return AppRemoteImage(
        url: profileImageUrl,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        fallbackIcon: Icons.alternate_email_rounded,
      );
    }
    return const Center(
      child: Icon(
        Icons.alternate_email_rounded,
        color: AppColors.cDBE7FE,
        size: 26,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.value);
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value.toUpperCase(),
      style: const TextStyle(
        color: AppColors.cFCFAFE,
        fontSize: 11,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  const _GlassTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.gB1BCFBTo393566,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.cFCFAFE.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: AppColors.cFCFAFE, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.cFCFAFE.withValues(alpha: 0.38)),
          filled: false,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: loading
              ? LinearGradient(
                  colors: [
                    AppColors.c393566.withValues(alpha: 0.50),
                    AppColors.cB1BCFB.withValues(alpha: 0.50),
                  ],
                )
              : AppGradients.gB1BCFBTo393566,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.cFCFAFE.withValues(alpha: 0.55),
            width: 1.5,
          ),
        ),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            foregroundColor: AppColors.cFCFAFE,
            disabledForegroundColor: AppColors.cFCFAFE.withValues(alpha: 0.5),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.cFCFAFE,
                  ),
                )
              : Text(label),
        ),
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  const _DangerButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.danger.withValues(alpha: 0.70),
            width: 1.5,
          ),
        ),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            foregroundColor: AppColors.danger,
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AppColors.danger),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
