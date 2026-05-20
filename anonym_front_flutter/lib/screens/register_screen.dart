import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_controller.dart';
import '../routes/app_routes.dart';
import '../theme.dart';
import '../validators/password_validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final RegExp _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  int _currentStep = 0;
  final int _totalSteps = 2;

  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _acceptTerms = false;
  bool _passTouched = false;
  bool _confirmTouched = false;
  bool _step1ValidationRequested = false;
  int _resendCooldownSeconds = 0;
  Timer? _resendCooldownTimer;

  final List<TextEditingController> _codeControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _codeFocusNodes = List.generate(6, (_) => FocusNode());

  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _emailCtrl.addListener(_refresh);
    _usernameCtrl.addListener(_refresh);
    _passCtrl.addListener(_refresh);
    _confirmPassCtrl.addListener(_refresh);
    for (final c in _codeControllers) {
      c.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _resendCooldownTimer?.cancel();
    _pageController.dispose();
    for (final c in [_emailCtrl, _usernameCtrl, _passCtrl, _confirmPassCtrl]) {
      c.removeListener(_refresh);
      c.dispose();
    }
    for (final c in _codeControllers) {
      c.removeListener(_refresh);
      c.dispose();
    }
    for (final f in _codeFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  bool get _isEmailValid => _emailRegExp.hasMatch(_emailCtrl.text.trim());
  bool get _isPasswordValid =>
      PasswordValidators.validate(_passCtrl.text.trim()).isEmpty;
  bool get _passwordsMatch =>
      _passCtrl.text.trim() == _confirmPassCtrl.text.trim();

  bool get _step1ReadyForSubmit =>
      _isEmailValid &&
      _usernameCtrl.text.trim().isNotEmpty &&
      _isPasswordValid &&
      _confirmPassCtrl.text.trim().isNotEmpty &&
      _acceptTerms;

  bool get _step2Valid =>
      _codeControllers.every((c) => c.text.trim().isNotEmpty);

  bool _isCurrentStepValid() =>
      _currentStep == 0 ? _step1ReadyForSubmit : _step2Valid;

  String get _verificationCode =>
      _codeControllers.map((c) => c.text.trim()).join();

  void _onVerificationCodeInput(int index, String rawValue) {
    final digits = rawValue.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      _codeControllers[index].clear();
      if (index > 0) {
        _codeFocusNodes[index - 1].requestFocus();
      }
      return;
    }

    if (digits.length == 1) {
      _codeControllers[index].value = TextEditingValue(
        text: digits,
        selection: const TextSelection.collapsed(offset: 1),
      );
      if (index == _codeControllers.length - 1) {
        _codeFocusNodes[index].unfocus();
      } else {
        _codeFocusNodes[index + 1].requestFocus();
      }
      return;
    }

    var writeIndex = index;
    for (final char in digits.characters) {
      if (writeIndex >= _codeControllers.length) break;
      _codeControllers[writeIndex].value = TextEditingValue(
        text: char,
        selection: const TextSelection.collapsed(offset: 1),
      );
      writeIndex++;
    }

    if (writeIndex >= _codeControllers.length) {
      _codeFocusNodes.last.unfocus();
    } else {
      _codeFocusNodes[writeIndex].requestFocus();
    }
  }

  Future<void> _nextPage() async {
    final auth = context.read<AuthController>();
    if (_currentStep == 0) {
      setState(() {
        _step1ValidationRequested = true;
      });
    }
    if (!_isCurrentStepValid() || auth.isBusy) return;

    if (_currentStep == 0) {
      if (!_passwordsMatch) {
        _showSnack(
          'Les mots de passe ne correspondent pas.',
          isError: true,
        );
        return;
      }
      final sent = await auth.requestRegisterCode(
        email: _emailCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      if (!mounted) return;
      if (!sent) {
        _applyRetryCooldownFrom(auth);
        _showSnack(
          auth.errorMessage ?? 'Envoi du code impossible',
          isError: true,
        );
        return;
      }
      _goToNextStep();
      _codeFocusNodes.first.requestFocus();
      _showSnack(
        auth.infoMessage ?? 'Code envoyé. Vérifie ton e-mail.',
        textColor: AppColors.textPrimary,
      );
    } else {
      final success = await auth.confirmRegister(
        email: _emailCtrl.text.trim(),
        code: _verificationCode,
      );
      if (!mounted) return;
      if (!success) {
        _showSnack(
          auth.errorMessage ?? 'Vérification impossible',
          isError: true,
        );
        return;
      }
      context.go(AppRoutes.app);
    }
  }

  void _goToNextStep() {
    if (_currentStep >= _totalSteps - 1) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep++);
  }

  Future<void> _resendCode() async {
    if (_resendCooldownSeconds > 0) return;
    final auth = context.read<AuthController>();
    if (auth.isBusy) return;

    final sent = await auth.requestRegisterCode(
      email: _emailCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      password: _passCtrl.text.trim(),
    );
    if (!mounted) return;
    if (!sent) {
      _applyRetryCooldownFrom(auth);
      _showSnack(
        auth.errorMessage ?? 'Envoi du code impossible',
        isError: true,
      );
      return;
    }

    _showSnack(
      auth.infoMessage ?? 'Code de vérification renvoyé avec succès.',
      textColor: AppColors.textPrimary,
    );
  }

  void _applyRetryCooldownFrom(AuthController auth) {
    final retry = auth.retryAfterSeconds;
    if (retry == null || retry <= 0) return;

    _resendCooldownTimer?.cancel();
    setState(() => _resendCooldownSeconds = retry);
    _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _resendCooldownSeconds = 0);
        return;
      }
      setState(() => _resendCooldownSeconds--);
    });
  }

  void _prevPage() {
    final auth = context.read<AuthController>();
    if (auth.isBusy) return;
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    } else {
      context.canPop() ? context.pop() : context.go(AppRoutes.auth);
    }
  }

  void _showSnack(
    String message, {
    bool isError = false,
    Color? textColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: textColor)),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
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
                    _buildStepIndicator(),
                    const SizedBox(height: 10),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          Center(child: _buildStep1()),
                          Center(child: _buildStep2()),
                        ],
                      ),
                    ),
                    _buildBottomActions(auth),
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
        _BackButton(onTap: _prevPage),
        const SizedBox(width: 16),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Align(
              key: ValueKey(_currentStep),
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titleForStep(_currentStep),
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Étape ${_currentStep + 1} sur $_totalSteps',
                    style: TextStyle(
                      color: AppColors.whiteColor.withValues(alpha: 0.45),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(_totalSteps, (i) {
        final isActive = i <= _currentStep;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 4,
            decoration: BoxDecoration(
              gradient: isActive
                  ? const LinearGradient(
                      colors: [Color(0xFFB1BCFB), Color(0xFFFCFAFE)],
                    )
                  : null,
              color: isActive
                  ? null
                  : AppColors.whiteColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBottomActions(AuthController auth) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: _PrimaryButton(
            label: _buttonText(auth.isBusy),
            isBusy: auth.isBusy,
            isEnabled: _isCurrentStepValid(),
            onTap: _nextPage,
          ),
        ),
        if (_currentStep == 0) ...[
          const SizedBox(height: 14),
          TextButton(
            onPressed: auth.isBusy ? null : () => context.go(AppRoutes.login),
            child: Text(
              'Déjà un compte ? Se connecter',
              style: TextStyle(
                color: AppColors.whiteColor.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ),
        ],
        if (_currentStep == 1) ...[
          const SizedBox(height: 14),
          TextButton(
            onPressed: auth.isBusy || _resendCooldownSeconds > 0
                ? null
                : _resendCode,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.refresh_rounded,
                  size: 14,
                  color: AppColors.whiteColor.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  _resendCooldownSeconds > 0
                      ? 'Renvoyer le code (${_resendCooldownSeconds}s)'
                      : 'Renvoyer le code',
                  style: TextStyle(
                    color: AppColors.whiteColor.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStep1() {
    final confirmMismatch =
        _step1ValidationRequested &&
        _isEmailValid &&
        _usernameCtrl.text.trim().isNotEmpty &&
        _isPasswordValid &&
        _confirmPassCtrl.text.trim().isNotEmpty &&
        !_passwordsMatch;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ModernField(
            label: 'E-mail',
            icon: Icons.alternate_email_rounded,
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            trailingIcon: _emailCtrl.text.trim().isNotEmpty
                ? (_isEmailValid
                      ? Icons.check_circle_rounded
                      : Icons.clear_rounded)
                : null,
            trailingColor: _emailCtrl.text.trim().isNotEmpty
                ? (_isEmailValid ? AppColors.success : AppColors.danger)
                : null,
          ),
          const SizedBox(height: 12),
          _ModernField(
            label: 'Pseudo',
            icon: Icons.person_rounded,
            controller: _usernameCtrl,
          ),
          const SizedBox(height: 12),
          _ModernField(
            label: 'Mot de passe',
            icon: Icons.lock_rounded,
            controller: _passCtrl,
            isPassword: true,
            onChanged: (_) => setState(() => _passTouched = true),
          ),
          const SizedBox(height: 10),
          _PasswordChecklist(
            password: _passCtrl.text.trim(),
            showState: _passTouched,
          ),
          const SizedBox(height: 12),
          _ModernField(
            label: 'Confirmation',
            icon: Icons.lock_outline_rounded,
            controller: _confirmPassCtrl,
            isPassword: true,
            onChanged: (_) => setState(() => _confirmTouched = true),
            trailingIcon:
                _confirmTouched && _confirmPassCtrl.text.trim().isNotEmpty
                ? (_passwordsMatch
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded)
                : null,
            trailingColor:
                _confirmTouched && _confirmPassCtrl.text.trim().isNotEmpty
                ? (_passwordsMatch ? AppColors.success : AppColors.danger)
                : null,
          ),
          if (confirmMismatch) ...[
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
          const SizedBox(height: 18),
          _TermsRow(
            accepted: _acceptTerms,
            onToggle: () => setState(() => _acceptTerms = !_acceptTerms),
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: AppColors.whiteColor,
                fontSize: 13,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: 'Entre le code reçu sur ton e-mail '),
                TextSpan(
                  text:
                      _emailCtrl.text.trim().isEmpty ? 'Votre e-mail' : _emailCtrl.text.trim(),
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: ' pour finaliser ton inscription.'),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              return _VerificationCodeField(
                index: index,
                controller: _codeControllers[index],
                focusNode: _codeFocusNodes[index],
                onChanged: _onVerificationCodeInput,
              );
            }),
          ),
        ],
      ),
    );
  }

  String _buttonText(bool isBusy) {
    if (isBusy) {
      return _currentStep == 0 ? 'Envoi du code en cours...' : 'Vérification en cours...';
    }
    return _currentStep == 0 ? 'Continuer' : "Valider l'inscription";
  }

  String _titleForStep(int step) => step == 0 ? 'Inscription' : 'Confirmation';
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
    this.trailingIcon,
    this.trailingColor,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final bool isPassword;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
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
          style: TextStyle(
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
                  ? const Color(0xFFB1BCFB).withValues(alpha: 0.80)
                  : Colors.transparent,
              width: _focused ? 1 : 0,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(
                widget.icon,
                size: 16,
                color: AppColors.whiteColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  obscureText: obscure,
                  onChanged: widget.onChanged,
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
    final oldMissingLabel = oldRules.where((r) => !r.$2).map((r) => r.$1).firstOrNull;
    final newMissingLabel = newRules.where((r) => !r.$2).map((r) => r.$1).firstOrNull;

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
                        Container(color: AppColors.whiteColor.withValues(alpha: 0.16)),
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
                        builder: (context, scale, child) => Transform.scale(
                          scale: scale,
                          child: child,
                        ),
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

class _TermsRow extends StatelessWidget {
  const _TermsRow({required this.accepted, required this.onToggle});
  final bool accepted;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              gradient: accepted ? AppGradients.gB1BCFBToFCFAFE : null,
              color: accepted
                  ? null
                  : AppColors.whiteColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: accepted
                    ? Colors.transparent
                    : AppColors.whiteColor.withValues(alpha: 0.2),
              ),
            ),
            child: accepted
                ? const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: AppColors.c393566,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: AppColors.whiteColor.withValues(alpha: 0.7),
                  fontSize: 13,
                  height: 1.4,
                ),
                children: const [
                  TextSpan(text: "J'accepte les "),
                  TextSpan(
                    text: 'conditions générales',
                    style: TextStyle(
                      color: Color(0xFFB1BCFB),
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xFFB1BCFB),
                    ),
                  ),
                  TextSpan(text: " d'utilisation"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationCodeField extends StatefulWidget {
  const _VerificationCodeField({
    required this.index,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final int index;
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(int index, String value) onChanged;

  @override
  State<_VerificationCodeField> createState() => _VerificationCodeFieldState();
}

class _VerificationCodeFieldState extends State<_VerificationCodeField> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = widget.focusNode.hasFocus;
    final hasValue = widget.controller.text.trim().isNotEmpty;
    return SizedBox(
      width: 46,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          gradient: isFocused
              ? const LinearGradient(colors: [Colors.white, Colors.white])
              : null,
          color: isFocused
              ? null
              : hasValue
              ? Colors.white.withValues(alpha: 0.35)
              : AppColors.whiteColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(13),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: AppColors.c393566,
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              cursorColor: Colors.white,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) => widget.onChanged(widget.index, value),
              style: const TextStyle(
                color: AppColors.whiteColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

