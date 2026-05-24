import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_controller.dart';
import '../services/admin_repository.dart';
import '../theme.dart';
import '../utils/api_error_parser.dart';
import '../widgets/chrome/moji_back_button.dart';
import '../widgets/modals/moji_confirm_modal.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key, this.confirmBeforeSubmit = false});

  final bool confirmBeforeSubmit;

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _submitting = false;

  bool get _isValid =>
      _subjectCtrl.text.trim().isNotEmpty &&
      _messageCtrl.text.trim().isNotEmpty;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_isValid || _submitting) return;
    final authController = context.read<AuthController>();
    final adminRepository = context.read<AdminRepository>();
    final messenger = ScaffoldMessenger.of(context);

    if (widget.confirmBeforeSubmit) {
      final confirmed = await _showSubmitConfirmModal();
      if (!mounted) return;
      if (!confirmed) return;
    }
    final userEmail = authController.user?.email.trim() ?? '';
    if (userEmail.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Email utilisateur introuvable')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final subject = _subjectCtrl.text.trim();
      final message = _messageCtrl.text.trim();
      await adminRepository.report(
        email: userEmail,
        type: 'feedback',
        content: 'Sujet: $subject\n\n$message',
      );
      if (!mounted) return;
      await _showSubmitSuccessModal();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            ApiErrorParser.parse(
              error,
              fallback: 'Impossible d envoyer le feedback pour le moment',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<bool> _showSubmitConfirmModal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => MojiConfirmModal(
        type: MojiConfirmModalType.warning,
        title: 'Envoyer ce signalement ?',
        description:
            'Ton signalement va etre transmis a l equipe pour verification.',
        confirmLabel: 'Envoyer',
        onConfirm: () => Navigator.of(dialogContext).pop(true),
        onCancel: () => Navigator.of(dialogContext).pop(false),
      ),
    );
    return confirmed == true;
  }

  Future<void> _showSubmitSuccessModal() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => MojiConfirmModal(
        type: MojiConfirmModalType.success,
        title: 'Feedback envoye',
        description:
            'Merci pour ton retour. L equipe va le traiter rapidement.',
        confirmLabel: 'Super',
        cancelLabel: 'Fermer',
        onConfirm: () => Navigator.of(dialogContext).pop(),
        onCancel: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: AppGradients.gB1BCFBTo393566,
              ),
            ),
          ),
          SafeArea(
            maintainBottomViewPadding: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const MojiBackButton(),
                      const SizedBox(width: 20),
                      Text(
                        'Feedback',
                        style: t.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Partagez vos retours pour nous aider a ameliorer l application',
                    style: t.bodyMedium?.copyWith(
                      color: AppColors.whiteColor.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        const _FieldLabel('Sujet'),
                        const SizedBox(height: 8),
                        _FeedbackField(
                          controller: _subjectCtrl,
                          hintText: 'Sujet',
                          maxLines: 1,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 18),
                        const _FieldLabel('Message'),
                        const SizedBox(height: 8),
                        _FeedbackField(
                          controller: _messageCtrl,
                          hintText: 'Message',
                          maxLines: 5,
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: (_isValid && !_submitting)
                            ? _onSubmit
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.whiteColor,
                          foregroundColor: AppColors.c393566,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: Text(
                          _submitting ? '...' : 'Envoyer le feedback',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackField extends StatelessWidget {
  const _FeedbackField({
    required this.controller,
    required this.hintText,
    required this.maxLines,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: AppGradients.gB1BCFBTo393566,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.cFCFAFE.withValues(alpha: 0.35),
          width: 1.1,
        ),
      ),
      child: Theme(
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
          onChanged: onChanged,
          style: const TextStyle(color: AppColors.whiteColor, fontSize: 15),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: AppColors.whiteColor.withValues(alpha: 0.55),
              fontSize: 15,
            ),
            fillColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Text(
      text,
      style: t.titleSmall?.copyWith(
        color: AppColors.whiteColor.withValues(alpha: 0.9),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
