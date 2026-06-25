import 'dart:io';

import 'package:file_selector/file_selector.dart' as fs;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/channel_model.dart';
import '../providers/app_providers.dart';
import '../providers/auth_providers.dart';
import '../theme.dart';
import '../widgets/app_remote_image.dart';
import '../widgets/navigation/anonym_back_button.dart';
import '../widgets/dialogs/anonym_confirm_dialog.dart';


part '../widgets/group_settings_screen_widgets.dart';

/// Écran de configuration d un groupe/canal.
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
    final app = context.watch<AppProvider>();
    final isPrivate = _visibility == 'PRIVATE';
    final currentUserId = context.watch<AuthProvider>().user?.id;
    final isCreator =
        currentUserId != null && currentUserId == widget.channel.createdBy;

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
                    AnonymBackButton(onTap: () => Navigator.of(context).pop()),
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
                      _GlassTextField(controller: _nameController, hint: ''),
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
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
                              onPressed:
                                  _imagePath != null ||
                                      ((widget.channel.coverImage ?? '')
                                              .isNotEmpty &&
                                          !_removeCurrentIcon)
                                  ? () => setState(() {
                                      _imagePath = null;
                                      _removeCurrentIcon = true;
                                    })
                                  : null,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.whiteColor,
                                side: BorderSide(
                                  color: AppColors.cFCFAFE.withValues(
                                    alpha: 0.10,
                                  ),
                                ),
                                backgroundColor: AppColors.danger,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
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
                        label: isCreator
                            ? 'Supprimer le groupe'
                            : 'Quitter le groupe',
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
        fs.XTypeGroup(
          label: 'images',
          extensions: ['jpg', 'jpeg', 'png', 'webp'],
        ),
      ],
    );
    if (file == null || file.path.isEmpty) return;
    setState(() {
      _imagePath = file.path;
      _removeCurrentIcon = false;
    });
  }

  Future<void> _save() async {
    await context.read<AppProvider>().updateSelectedGroup(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      visibility: _visibility,
      imageFilePath: _imagePath,
    );
    if (!mounted) return;
    final error = context.read<AppProvider>().errorMessage;
    if (error != null && error.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _handleLeaveOrDelete(bool isCreator) async {
    final app = context.read<AppProvider>();
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(context).pop();
  }

  Future<bool?> _showDeleteGroupConfirmModal() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AnonymConfirmDialog(
          type: AnonymConfirmDialogType.danger,
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
