import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_controller.dart';
import '../routes/app_routes.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _identifierController.addListener(_refresh);
    _passwordController.addListener(_refresh);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _identifierController.removeListener(_refresh);
    _passwordController.removeListener(_refresh);
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  bool get _canLogin =>
      _identifierController.text.trim().isNotEmpty &&
      _passwordController.text.trim().isNotEmpty;

  Future<void> _login() async {
    if (!_canLogin) return;

    final auth = context.read<AuthController>();
    final success = await auth.login(
      identifier: _identifierController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    if (success) {
      context.go(AppRoutes.app);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(auth.errorMessage ?? 'Erreur de connexion'),
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
      context.go(AppRoutes.auth);
    }
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
                    const SizedBox(height: 22),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _LoginField(
                                label: "E-mail ou pseudo",
                                controller: _identifierController,
                                icon: Icons.alternate_email_rounded,
                              ),
                              const SizedBox(height: 12),
                              _LoginField(
                                label: 'Mot de passe',
                                controller: _passwordController,
                                icon: Icons.lock_rounded,
                                obscureText: _obscurePassword,
                                trailing: IconButton(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 10),
                                  constraints: const BoxConstraints(),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.whiteColor,
                                    size: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: () =>
                                      context.go(AppRoutes.resetPassword),
                                  child: Text(
                                    'Mot de passe oublie ?',
                                    style: TextStyle(
                                      color: AppColors.whiteColor
                                          .withValues(alpha: 0.7),
                                      decoration: TextDecoration.underline,
                                      decorationColor: AppColors.whiteColor
                                          .withValues(alpha: 0.7),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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
                color: const Color(0xFFB1BCFB).withValues(alpha: 0.18 + t * 0.06),
              ),
            ),
            Positioned(
              bottom: 40 - t * 20,
              left: -80,
              child: _GlowOrb(
                size: 220,
                color: const Color(0xFF393566).withValues(alpha: 0.35 + t * 0.1),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connexion',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 2),
              Text(
                'Ravi de te revoir',
                style: TextStyle(
                  color: AppColors.whiteColor.withValues(alpha: 0.45),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(AuthController auth) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: _PrimaryButton(
            label: auth.isBusy ? 'Connexion...' : 'Connexion',
            isBusy: auth.isBusy,
            isEnabled: _canLogin,
            onTap: _login,
          ),
        ),
        const SizedBox(height: 14),
        TextButton(
          onPressed: auth.isBusy ? null : () => context.go(AppRoutes.register),
          child: Text(
            'Pas encore de compte ? Je m\'inscris',
            style: TextStyle(
              color: AppColors.whiteColor.withValues(alpha: 0.7),
              fontSize: 13,
            ),
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
          border: Border.all(color: AppColors.whiteColor.withValues(alpha: 0.15)),
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
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.c393566),
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

class _LoginField extends StatefulWidget {
  const _LoginField({
    required this.label,
    required this.controller,
    required this.icon,
    this.obscureText = false,
    this.trailing,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool obscureText;
  final Widget? trailing;

  @override
  State<_LoginField> createState() => _LoginFieldState();
}

class _LoginFieldState extends State<_LoginField> {
  bool _focused = false;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode()..addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  obscureText: widget.obscureText,
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
              if (widget.trailing != null) ...[
                widget.trailing!,
                const SizedBox(width: 4),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
