part of '../screens/register_screen.dart';

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
      hint: "Revient a l'etape precedente",
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
          ? "Continue le parcours d'inscription"
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
        Semantics(
          textField: true,
          label: widget.label,
          hint: widget.isPassword
              ? 'Champ de saisie securisee'
              : 'Champ de saisie ${widget.label}',
          child: AnimatedContainer(
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
                    obscureText: obscure,
                    onChanged: widget.onChanged,
                    keyboardType: widget.keyboardType,
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
                if (widget.isPassword)
                  IconButton(
                    tooltip: obscure
                        ? 'Afficher ${widget.label.toLowerCase()}'
                        : 'Masquer ${widget.label.toLowerCase()}',
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
                    child: ExcludeSemantics(
                      child: Icon(
                        widget.trailingIcon,
                        size: 16,
                        color: widget.trailingColor,
                      ),
                    ),
                  ),
              ],
            ),
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
      ('Minimum 12 caractères', PasswordValidators.hasMinLength(password)),
      ('Au moins 1 minuscule', PasswordValidators.hasLowercase(password)),
      ('Au moins 1 majuscule', PasswordValidators.hasUppercase(password)),
      ('Au moins 1 chiffre', PasswordValidators.hasNumber(password)),
      ('Au moins 1 caractère spécial', PasswordValidators.hasSymbol(password)),
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

    return Semantics(
      label: 'Regles du mot de passe',
      value: '$completed regles validees sur ${rules.length}',
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.whiteColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.whiteColor.withValues(alpha: 0.1),
          ),
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
                      'Commence à saisir ton mot de passe',
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
    return Semantics(
      button: true,
      checked: accepted,
      label: "Accepter les conditions generales d'utilisation",
      hint: accepted
          ? 'Conditions acceptees'
          : 'Active cette option pour continuer',
      child: GestureDetector(
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
                  ? const ExcludeSemantics(
                      child: Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: AppColors.c393566,
                      ),
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
    return Semantics(
      textField: true,
      label: 'Code de verification chiffre ${widget.index + 1}',
      hint: 'Saisis un chiffre du code recu par e-mail',
      child: SizedBox(
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
                decoration: InputDecoration(
                  labelText: 'Code de verification chiffre ${widget.index + 1}',
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  labelStyle: const TextStyle(fontSize: 0, height: 0),
                  counterText: '',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
