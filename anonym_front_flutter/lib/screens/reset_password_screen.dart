import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_controller.dart';
import '../routes/app_routes.dart';
import '../theme.dart';
import '../validators/auth_validators.dart';
import '../validators/password_validators.dart';
import '../widgets/modals/moji_confirm_modal.dart';

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
    final title = _hasToken ? 'Mot de passe reinitialise' : 'Email envoye';
    final description = _hasToken
        ? 'Ton mot de passe a bien ete mis a jour. Tu peux maintenant te connecter.'
        : 'Un email de reinitialisation vient d etre envoye. Verifie ta boite mail.';
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => MojiConfirmModal(
        type: MojiConfirmModalType.success,
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
    final auth = context.watch<AuthController>();
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

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.whiteColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: AppColors.whiteColor.withValues(alpha: 0.15),
          ),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: AppColors.whiteColor,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.isBusy,
    required this.isEnabled,
    required this.onTap,
  });

  final String label;
  final bool isBusy;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = isEnabled && !isBusy;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.4,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.whiteColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: isBusy
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.c393566,
                      ),
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.c393566,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ModernField extends StatefulWidget {
  const _ModernField({
    required this.label,
    required this.icon,
    required this.controller,
    this.isPassword = false,
    this.onChanged,
    this.keyboardType,
    this.validator,
    this.trailingIcon,
    this.trailingColor,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final bool isPassword;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final IconData? trailingIcon;
  final Color? trailingColor;

  @override
  State<_ModernField> createState() => _ModernFieldState();
}

class _ModernFieldState extends State<_ModernField> {
  bool _obscure = true;
  bool _focused = false;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode()
      ..addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final obscure = widget.isPassword && _obscure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: AppColors.whiteColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: AppGradients.gB1BCFBTo393566,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused
                  ? const Color(0xFFB1BCFB).withValues(alpha: 0.8)
                  : Colors.transparent,
              width: _focused ? 1 : 0,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(widget.icon, size: 16, color: AppColors.whiteColor),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focus,
                  obscureText: obscure,
                  onChanged: widget.onChanged,
                  validator: widget.validator,
                  keyboardType: widget.keyboardType,
                  style: const TextStyle(
                    color: AppColors.whiteColor,
                    fontSize: 14,
                  ),
                  cursorColor: AppColors.whiteColor,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    isDense: true,
                    filled: false,
                    fillColor: Colors.transparent,
                    contentPadding: EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
              if (widget.isPassword)
                IconButton(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 16,
                    color: AppColors.whiteColor,
                  ),
                )
              else if (widget.trailingIcon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    widget.trailingIcon,
                    size: 16,
                    color: widget.trailingColor,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PasswordChecklist extends StatefulWidget {
  const _PasswordChecklist({required this.password, required this.showState});

  final String password;
  final bool showState;

  @override
  State<_PasswordChecklist> createState() => _PasswordChecklistState();
}

class _PasswordChecklistState extends State<_PasswordChecklist> {
  String? _justCompletedLabel;
  Timer? _transitionTimer;

  List<(String, bool)> _rulesFor(String password) {
    return [
      ('Minimum 12 caracteres', PasswordValidators.hasMinLength(password)),
      ('Au moins 1 minuscule', PasswordValidators.hasLowercase(password)),
      ('Au moins 1 majuscule', PasswordValidators.hasUppercase(password)),
      ('Au moins 1 chiffre', PasswordValidators.hasNumber(password)),
      ('Au moins 1 caractere special', PasswordValidators.hasSymbol(password)),
    ];
  }

  @override
  void didUpdateWidget(covariant _PasswordChecklist oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.showState) {
      _transitionTimer?.cancel();
      _justCompletedLabel = null;
      return;
    }

    final oldRules = _rulesFor(oldWidget.password);
    final newRules = _rulesFor(widget.password);
    final oldMissingLabel = oldRules
        .where((r) => !r.$2)
        .map((r) => r.$1)
        .firstOrNull;
    final newMissingLabel = newRules
        .where((r) => !r.$2)
        .map((r) => r.$1)
        .firstOrNull;

    if (oldMissingLabel != null &&
        oldMissingLabel != newMissingLabel &&
        newRules.where((r) => r.$1 == oldMissingLabel).first.$2) {
      final completedLabel = oldMissingLabel;
      _transitionTimer?.cancel();
      setState(() => _justCompletedLabel = completedLabel);
      _transitionTimer = Timer(const Duration(milliseconds: 650), () {
        if (!mounted) return;
        setState(() => _justCompletedLabel = null);
      });
    } else if (newMissingLabel != oldMissingLabel) {
      _transitionTimer?.cancel();
      if (_justCompletedLabel != null) {
        setState(() => _justCompletedLabel = null);
      }
    }
  }

  @override
  void dispose() {
    _transitionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rules = _rulesFor(widget.password);
    final completed = rules.where((r) => r.$2).length;
    final progress = completed / rules.length;
    final missing = rules.where((r) => !r.$2).toList(growable: false);
    final nextMissing = missing.isNotEmpty ? missing.first : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.whiteColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.whiteColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 7,
                    child: Stack(
                      children: [
                        Container(
                          color: AppColors.whiteColor.withValues(alpha: 0.16),
                        ),
                        AnimatedFractionallySizedBox(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(color: _strengthColor(completed)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$completed/${rules.length}',
                style: TextStyle(
                  color: AppColors.whiteColor.withValues(alpha: 0.78),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(sizeFactor: animation, child: child),
            ),
            child: !widget.showState
                ? Text(
                    'Commence a saisir ton mot de passe',
                    key: const ValueKey('idle'),
                    style: TextStyle(
                      color: AppColors.whiteColor.withValues(alpha: 0.65),
                      fontSize: 12.5,
                    ),
                  )
                : _justCompletedLabel != null
                ? Row(
                    key: ValueKey('just-done-$_justCompletedLabel'),
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.7, end: 1),
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutBack,
                        builder: (context, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _justCompletedLabel!,
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  )
                : nextMissing == null
                ? const Row(
                    key: ValueKey('done'),
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mot de passe conforme',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    key: ValueKey(nextMissing.$1),
                    children: [
                      const Icon(
                        Icons.radio_button_unchecked_rounded,
                        color: AppColors.cDBE7FE,
                        size: 15,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          nextMissing.$1,
                          style: const TextStyle(
                            color: AppColors.cDBE7FE,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Color _strengthColor(int completed) {
    if (completed <= 1) return AppColors.danger;
    if (completed == 2) return const Color(0xFFEF9F27);
    if (completed == 3 || completed == 4) return const Color(0xFFF3D34A);
    return AppColors.success;
  }
}
