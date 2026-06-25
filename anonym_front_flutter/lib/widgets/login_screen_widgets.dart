part of '../screens/login_screen.dart';

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
    return Semantics(
      button: true,
      label: 'Retour',
      hint: "Revient a l'ecran precedent",
      child: GestureDetector(
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
          child: const ExcludeSemantics(
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: AppColors.whiteColor,
            ),
          ),
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
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      hint: enabled
          ? 'Valide le formulaire de connexion'
          : 'Action indisponible',
      child: AnimatedOpacity(
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
        Semantics(
          textField: true,
          label: widget.label,
          hint: widget.obscureText
              ? 'Champ de saisie securisee'
              : 'Saisis ton e-mail ou ton pseudo',
          child: AnimatedContainer(
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
                ExcludeSemantics(
                  child: Icon(
                    widget.icon,
                    size: 16,
                    color: AppColors.whiteColor,
                  ),
                ),
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
                    decoration: InputDecoration(
                      labelText: widget.label,
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      labelStyle: const TextStyle(fontSize: 0, height: 0),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      isDense: true,
                      filled: false,
                      fillColor: Colors.transparent,
                      contentPadding: const EdgeInsets.symmetric(vertical: 13),
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
        ),
      ],
    );
  }
}
