import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_providers.dart';
import '../routes/app_routes.dart';
import '../theme.dart';
import '../validators/auth_validators.dart';
import '../validators/password_validators.dart';
import '../widgets/dialogs/anonym_confirm_dialog.dart';


part '../widgets/reset_password_screen_widgets.dart';

/// Écran de demande et validation de réinitialisation de mot de passe.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.token});

  final String? token;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _hasTriedSubmit = false;
  bool _passTouched = false;
  bool _confirmTouched = false;
  late final AnimationController _glowController;

  bool get _hasToken => (widget.token ?? '').trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _passwordsMatch =>
      _passwordController.text.trim().isNotEmpty &&
      _confirmPasswordController.text.trim().isNotEmpty &&
      _passwordController.text.trim() == _confirmPasswordController.text.trim();

  bool get _canSubmitPasswordUpdate {
    if (!_hasToken) return true;
    final password = _passwordController.text.trim();
    return PasswordValidators.validate(password).isEmpty &&
        _confirmPasswordController.text.trim().isNotEmpty;
  }

  Future<void> _submit() async {
    setState(() => _hasTriedSubmit = true);
    if (!_formKey.currentState!.validate()) return;
    if (_hasToken && !_passwordsMatch) return;

    final auth = context.read<AuthProvider>();

    final success = _hasToken
        ? await auth.completePasswordReset(
            token: widget.token!.trim(),
            password: _passwordController.text.trim(),
            confirmPassword: _confirmPasswordController.text.trim(),
          )
        : await auth.requestPasswordReset(email: _emailController.text.trim());

    if (!mounted) return;

    if (success) {
      await _showResetSuccessModal();
      if (!mounted) return;
      context.go(AppRoutes.login);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(auth.errorMessage ?? 'Erreur de réinitialisation'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.login);
    }
  }

  Future<void> _showResetSuccessModal() async {
    final title = _hasToken ? 'Mot de passe réinitialisé' : 'Email envoyé';
    final description = _hasToken
        ? 'Ton mot de passe a bien été mis à jour. Tu peux maintenant te connecter.'
        : 'Un email de réinitialisation vient d\'être envoyé. Vérifie ta boîte mail.';
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AnonymConfirmDialog(
        type: AnonymConfirmDialogType.success,
        title: title,
        description: description,
        confirmLabel: 'Continuer',
        cancelLabel: 'Fermer',
        onConfirm: () => Navigator.of(dialogContext).pop(),
        onCancel: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final showConfirmMismatch =
        _hasToken &&
        _hasTriedSubmit &&
        _passwordController.text.trim().isNotEmpty &&
        _confirmPasswordController.text.trim().isNotEmpty &&
        !_passwordsMatch;

    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.gB1BCFBTo393566),
      child: Stack(
        children: [
          _buildGlowOrbs(),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildTopBar(),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Form(
                        key: _formKey,
                        autovalidateMode: _hasTriedSubmit
                            ? AutovalidateMode.onUserInteraction
                            : AutovalidateMode.disabled,
                        onChanged: () => setState(() {}),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _hasToken
                                    ? 'Choisis ton nouveau mot de passe.'
                                    : 'Saisis ton email pour recevoir un lien de réinitialisation.',
                                style: TextStyle(
                                  color: AppColors.whiteColor.withValues(
                                    alpha: 0.65,
                                  ),
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (!_hasToken) ...[
                                _ModernField(
                                  label: 'Email',
                                  icon: Icons.alternate_email_rounded,
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: AuthValidators.email,
                                ),
                              ],
                              if (_hasToken) ...[
                                _ModernField(
                                  label: 'Nouveau mot de passe',
                                  icon: Icons.lock_rounded,
                                  controller: _passwordController,
                                  isPassword: true,
                                  onChanged: (_) =>
                                      setState(() => _passTouched = true),
                                  validator:
                                      PasswordValidators.validateAsString,
                                ),
                                const SizedBox(height: 10),
                                _PasswordChecklist(
                                  password: _passwordController.text.trim(),
                                  showState: _passTouched,
                                ),
                                const SizedBox(height: 14),
                                _ModernField(
                                  label: 'Répéter le nouveau mot de passe',
                                  icon: Icons.lock_outline_rounded,
                                  controller: _confirmPasswordController,
                                  isPassword: true,
                                  onChanged: (_) =>
                                      setState(() => _confirmTouched = true),
                                  trailingIcon:
                                      _confirmTouched &&
                                          _confirmPasswordController.text
                                              .trim()
                                              .isNotEmpty
                                      ? (_passwordsMatch
                                            ? Icons.check_circle_rounded
                                            : Icons.cancel_rounded)
                                      : null,
                                  trailingColor:
                                      _confirmTouched &&
                                          _confirmPasswordController.text
                                              .trim()
                                              .isNotEmpty
                                      ? (_passwordsMatch
                                            ? AppColors.success
                                            : AppColors.danger)
                                      : null,
                                  validator: (value) {
                                    final text = (value ?? '').trim();
                                    if (text.isEmpty) return 'Champ requis';
                                    return null;
                                  },
                                ),
                                if (showConfirmMismatch) ...[
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Les mots de passe ne correspondent pas.',
                                    style: TextStyle(
                                      color: AppColors.danger,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: _PrimaryButton(
                        label: auth.isBusy
                            ? '...'
                            : _hasToken
                            ? 'Changer le mot de passe'
                            : 'Envoyer',
                        isBusy: auth.isBusy,
                        isEnabled: _canSubmitPasswordUpdate,
                        onTap: _submit,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowOrbs() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final t = _glowController.value;
        return Stack(
          children: [
            Positioned(
              top: -80 + t * 20,
              right: -60 + t * 15,
              child: _GlowOrb(
                size: 260,
                color: const Color(
                  0xFFB1BCFB,
                ).withValues(alpha: 0.18 + t * 0.06),
              ),
            ),
            Positioned(
              bottom: 40 - t * 20,
              left: -80,
              child: _GlowOrb(
                size: 220,
                color: const Color(
                  0xFF393566,
                ).withValues(alpha: 0.35 + t * 0.1),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        _BackButton(onTap: _goBack),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            _hasToken
                ? 'Nouveau mot de passe'
                : 'Réinitialiser le mot de passe',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
        ),
      ],
    );
  }
}
