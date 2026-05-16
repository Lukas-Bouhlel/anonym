import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_controller.dart';
import '../routes/app_routes.dart';
import '../theme.dart';
import '../validators/auth_validators.dart';
import '../validators/password_validators.dart';
import '../widgets/chrome/moji_back_button.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.token});

  final String? token;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _hasTriedSubmit = false;

  bool get _hasToken => (widget.token ?? '').trim().isNotEmpty;

  @override
  void dispose() {
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
    return PasswordValidators.validate(password).isEmpty && _passwordsMatch;
  }

  Future<void> _submit() async {
    setState(() => _hasTriedSubmit = true);
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthController>();

    final success = _hasToken
        ? await auth.completePasswordReset(
            token: widget.token!.trim(),
            password: _passwordController.text.trim(),
            confirmPassword: _confirmPasswordController.text.trim(),
          )
        : await auth.requestPasswordReset(email: _emailController.text.trim());

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _hasToken
                ? 'Mot de passe réinitialisé avec succès.'
                : 'Email de réinitialisation envoyé.',
          ),
        ),
      );
      context.go(AppRoutes.login);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(auth.errorMessage ?? 'Erreur de réinitialisation')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.gB1BCFBTo393566),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const MojiBackButton(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        _hasToken
                            ? 'Nouveau mot de passe'
                            : 'Réinitialiser le mot de passe',
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _hasToken
                      ? 'Le nouveau mot de passe doit contenir au minimum 12 caractères, une minuscule, une majuscule, un chiffre et un caractère spécial.'
                      : 'Saisis ton email pour recevoir un lien de réinitialisation.',
                  style: const TextStyle(
                    color: AppColors.cDBE7FE,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _hasTriedSubmit
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    onChanged: () => setState(() {}),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        if (!_hasToken) ...[
                          const _FieldLabel('Email'),
                          const SizedBox(height: 8),
                          _MojiTextField(
                            controller: _emailController,
                            hintText: 'Email',
                            keyboardType: TextInputType.emailAddress,
                            validator: AuthValidators.email,
                          ),
                        ],
                        if (_hasToken) ...[
                          const _FieldLabel('Nouveau mot de passe'),
                          const SizedBox(height: 8),
                          _MojiTextField(
                            controller: _passwordController,
                            hintText: 'Nouveau mot de passe',
                            obscureText: true,
                            validator: PasswordValidators.validateAsString,
                          ),
                          const SizedBox(height: 10),
                          _PasswordHints(
                            password: _passwordController.text.trim(),
                            passwordsMatch: _passwordsMatch,
                          ),
                          const SizedBox(height: 18),
                          const _FieldLabel('Répéter le nouveau mot de passe'),
                          const SizedBox(height: 8),
                          _MojiTextField(
                            controller: _confirmPasswordController,
                            hintText: 'Répéter le nouveau mot de passe',
                            obscureText: true,
                            validator: (value) {
                              final text = (value ?? '').trim();
                              if (text.isEmpty) return 'Champ requis';
                              if (text != _passwordController.text.trim()) {
                                return 'Les mots de passe ne correspondent pas';
                              }
                              return null;
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: auth.isBusy || !_canSubmitPasswordUpdate
                        ? null
                        : _submit,
                    child: Text(
                      auth.isBusy
                          ? '...'
                          : _hasToken
                          ? 'Changer le mot de passe'
                          : 'Envoyer',
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.whiteColor,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _MojiTextField extends StatelessWidget {
  const _MojiTextField({
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: AppColors.whiteColor,
        fontSize: 14,
      ),
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.cDBE7FE),
        errorMaxLines: 2,
      ),
    );
  }
}

class _PasswordHints extends StatelessWidget {
  const _PasswordHints({required this.password, required this.passwordsMatch});

  final String password;
  final bool passwordsMatch;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _PasswordRequirementChip(
          label: '12 caractères',
          isValid: PasswordValidators.hasMinLength(password),
        ),
        _PasswordRequirementChip(
          label: '1 majuscule',
          isValid: PasswordValidators.hasUppercase(password),
        ),
        _PasswordRequirementChip(
          label: '1 minuscule',
          isValid: PasswordValidators.hasLowercase(password),
        ),
        _PasswordRequirementChip(
          label: '1 chiffre',
          isValid: PasswordValidators.hasNumber(password),
        ),
        _PasswordRequirementChip(
          label: '1 symbole',
          isValid: PasswordValidators.hasSymbol(password),
        ),
        _PasswordRequirementChip(
          label: 'Confirmation identique',
          isValid: passwordsMatch,
        ),
      ],
    );
  }
}

class _PasswordRequirementChip extends StatelessWidget {
  const _PasswordRequirementChip({required this.label, required this.isValid});

  final String label;
  final bool isValid;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isValid
        ? AppColors.cCFFFDD.withValues(alpha: 0.16)
        : AppColors.cFF6565.withValues(alpha: 0.16);
    final borderColor = isValid
        ? AppColors.cCFFFDD
        : AppColors.cFF6565;
    final textColor = isValid
        ? AppColors.cCFFFDD
        : AppColors.cFF6565;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
