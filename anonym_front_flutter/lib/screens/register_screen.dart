import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_providers.dart';
import '../routes/app_routes.dart';
import '../theme.dart';
import '../validators/password_validators.dart';
import '../widgets/dialogs/anonym_confirm_dialog.dart';

part '../widgets/register_screen_widgets.dart';

/// Écran d inscription et validation de compte.
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
    final auth = context.read<AuthProvider>();
    if (_currentStep == 0) {
      setState(() {
        _step1ValidationRequested = true;
      });
    }
    if (!_isCurrentStepValid() || auth.isBusy) return;

    if (_currentStep == 0) {
      if (!_passwordsMatch) {
        _showSnack('Les mots de passe ne correspondent pas.', isError: true);
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
        activateSession: false,
      );
      if (!mounted) return;
      if (!success) {
        _showSnack(
          auth.errorMessage ?? 'Vérification impossible',
          isError: true,
        );
        return;
      }
      await _showRegistrationSuccessModal();
      if (!mounted) return;
      auth.activatePendingRegistration();
      context.go(AppRoutes.app);
    }
  }

  Future<void> _showRegistrationSuccessModal() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AnonymConfirmDialog(
        type: AnonymConfirmDialogType.success,
        title: 'Inscription terminée',
        description:
            'Ton compte est prêt. Tu peux maintenant commencer sur Anonym.',
        confirmLabel: 'Continuer',
        cancelLabel: 'Fermer',
        onConfirm: () => Navigator.of(dialogContext).pop(),
        onCancel: () => Navigator.of(dialogContext).pop(),
      ),
    );
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
    final auth = context.read<AuthProvider>();
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

  void _applyRetryCooldownFrom(AuthProvider auth) {
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
    final auth = context.read<AuthProvider>();
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

  void _showSnack(String message, {bool isError = false, Color? textColor}) {
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
    final auth = context.watch<AuthProvider>();
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

  Widget _buildBottomActions(AuthProvider auth) {
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
                  text: _emailCtrl.text.trim().isEmpty
                      ? 'Votre e-mail'
                      : _emailCtrl.text.trim(),
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
      return _currentStep == 0
          ? 'Envoi du code en cours...'
          : 'Vérification en cours...';
    }
    return _currentStep == 0 ? 'Continuer' : "Valider l'inscription";
  }

  String _titleForStep(int step) => step == 0 ? 'Inscription' : 'Confirmation';
}
