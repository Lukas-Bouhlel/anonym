import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_controller.dart';
import '../theme.dart';
import '../widgets/chrome/moji_back_button.dart';

// ─── Regex ───────────────────────────────────────────────────────────────────
final RegExp _reLower   = RegExp(r'[a-z]');
final RegExp _reUpper   = RegExp(r'[A-Z]');
final RegExp _reDigit   = RegExp(r'[0-9]');
final RegExp _reSpecial = RegExp(r"""[!@#\$%^&*()\-_=+\[\]{};'",.<>/?`~|\\]""");

class _Rule {
  const _Rule(this.label, this.test);
  final String label;
  final bool Function(String) test;
}

const List<_Rule> _passwordRules = [
  _Rule('Minimum 12 caractères',                     _checkLen),
  _Rule('Au moins 1 minuscule (a-z)',                _checkLower),
  _Rule('Au moins 1 majuscule (A-Z)',                _checkUpper),
  _Rule('Au moins 1 chiffre (0-9)',                  _checkDigit),
  _Rule('Au moins 1 caractère spécial (!@#\$%^&*…)', _checkSpecial),
];

bool _checkLen(String v)     => v.length >= 12;
bool _checkLower(String v)   => _reLower.hasMatch(v);
bool _checkUpper(String v)   => _reUpper.hasMatch(v);
bool _checkDigit(String v)   => _reDigit.hasMatch(v);
bool _checkSpecial(String v) => _reSpecial.hasMatch(v);

// ─── Screen ──────────────────────────────────────────────────────────────────
class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final _currentController = TextEditingController();
  final _newController      = TextEditingController();
  final _confirmController  = TextEditingController();

  bool _newTouched     = false;
  bool _confirmTouched = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ── Derived state ──────────────────────────────────────────────────────────

  bool _ruleOk(_Rule rule) => rule.test(_newController.text);
  bool get _allRulesOk     => _passwordRules.every(_ruleOk);
  bool get _passwordsMatch =>
      _newController.text == _confirmController.text &&
      _confirmController.text.isNotEmpty;
  bool get _canSubmit =>
      _currentController.text.isNotEmpty && _allRulesOk && _passwordsMatch;

  int get _strength {
    final v = _newController.text;
    if (v.isEmpty) return 0;
    final score = _passwordRules.where((r) => r.test(v)).length;
    return score.clamp(1, 4).toInt();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _submit(BuildContext context, AppController app) async {
    await app.updatePassword(
      currentPassword:    _currentController.text.trim(),
      newPassword:        _newController.text.trim(),
      confirmNewPassword: _confirmController.text.trim(),
    );
    if (!context.mounted) return;
    if (app.errorMessage != null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mot de passe mis à jour')),
    );
    Navigator.of(context).pop();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.gB1BCFBTo393566),
        child: SafeArea(
          child: Consumer<AppController>(
            builder: (context, app, _) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  // ── Header ──────────────────────────────────────────────
                  Row(children: [
                    const MojiBackButton(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Mot de passe',
                        style: t.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  const Text(
                    'Mets à jour ton mot de passe en renseignant les champs ci-dessous.',
                    style: TextStyle(color: AppColors.cDBE7FE, fontSize: 14),
                  ),
                  const SizedBox(height: 22),

                  // ── Mot de passe actuel ──────────────────────────────────
                  _PasswordField(
                    controller: _currentController,
                    label: 'Mot de passe actuel',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // ── Nouveau mot de passe ─────────────────────────────────
                  AnimatedBuilder(
                    animation: _newController,
                    builder: (context, _) {
                      return _PasswordField(
                        controller: _newController,
                        label: 'Nouveau mot de passe',
                        hasError: _newTouched && !_allRulesOk,
                        isValid:  _newTouched && _allRulesOk,
                        onChanged: (_) => setState(() { _newTouched = true; }),
                      );
                    },
                  ),

                  // ── Barre de force ───────────────────────────────────────
                  if (_newTouched) ...[
                    const SizedBox(height: 10),
                    _StrengthBar(strength: _strength),
                    const SizedBox(height: 4),
                    _StrengthLabel(strength: _strength),
                  ],
                  const SizedBox(height: 10),

                  // ── Règles de validation ─────────────────────────────────
                  _ValidationRules(
                    rules: _passwordRules,
                    value: _newController.text,
                    touched: _newTouched,
                  ),
                  const SizedBox(height: 12),

                  // ── Confirmation ─────────────────────────────────────────
                  AnimatedBuilder(
                    animation: _confirmController,
                    builder: (context, _) {
                      return _PasswordField(
                        controller: _confirmController,
                        label: 'Confirmation',
                        hasError: _confirmTouched && !_passwordsMatch,
                        isValid:  _confirmTouched && _passwordsMatch,
                        onChanged: (_) => setState(() { _confirmTouched = true; }),
                      );
                    },
                  ),

                  // ── Hint correspondance ──────────────────────────────────
                  if (_confirmTouched && _confirmController.text.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _MatchHint(matches: _passwordsMatch),
                  ],
                  const SizedBox(height: 22),

                  // ── Bouton ───────────────────────────────────────────────
                  FilledButton(
                    onPressed: (app.isSubmitting || !_canSubmit)
                        ? null
                        : () => _submit(context, app),
                    child: app.isSubmitting
                        ? const SizedBox(
                            height: 18, width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Mettre à jour'),
                  ),

                  // ── Erreur globale ───────────────────────────────────────
                  if (app.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        app.errorMessage!,
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Widgets privés ──────────────────────────────────────────────────────────

class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    this.hasError = false,
    this.isValid  = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final bool hasError;
  final bool isValid;
  final ValueChanged<String>? onChanged;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  Color get _borderColor {
    if (widget.isValid)  return const Color(0xFF1D9E75);
    if (widget.hasError) return const Color(0xFFE24B4A);
    return Colors.white24;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppGradients.gB1BCFBTo393566,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: widget.isValid || widget.hasError
              ? _borderColor
              : AppColors.cFCFAFE.withValues(alpha: 0.35),
          width: widget.isValid || widget.hasError ? 1.5 : 1.1,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        obscureText: _obscure,
        onChanged: widget.onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: const TextStyle(color: AppColors.cDBE7FE, fontSize: 14),
          filled: false,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 0, 16),
          suffixIcon: IconButton(
            icon: Icon(
              _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 20,
              color: AppColors.cDBE7FE,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
      ),
    );
  }
}

// ── Règles ──────────────────────────────────────────────────────────────────

class _ValidationRules extends StatelessWidget {
  const _ValidationRules({
    required this.rules,
    required this.value,
    required this.touched,
  });

  final List<_Rule> rules;
  final String value;
  final bool touched;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: touched ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: rules.map((r) => _RuleRow(
            label: r.label,
            ok: r.test(value),
            touched: touched,
          )).toList(),
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.label, required this.ok, required this.touched});
  final String label;
  final bool ok;
  final bool touched;

  @override
  Widget build(BuildContext context) {
    final Color color = !touched
        ? AppColors.cDBE7FE
        : ok
            ? const Color(0xFF1D9E75)
            : const Color(0xFFE24B4A);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 18, height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: touched ? (ok ? const Color(0xFF1D9E75) : const Color(0xFFE24B4A)) : Colors.transparent,
              border: Border.all(
                color: touched ? Colors.transparent : Colors.white30,
                width: 1.5,
              ),
            ),
            child: touched
                ? Icon(ok ? Icons.check : Icons.close, size: 11, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ── Barre de force ───────────────────────────────────────────────────────────

class _StrengthBar extends StatelessWidget {
  const _StrengthBar({required this.strength});
  final int strength; // 0-4

  static const _colors = [
    Colors.transparent,
    Color(0xFFE24B4A),
    Color(0xFFEF9F27),
    Color(0xFF1D9E75),
    Color(0xFF7F77DD),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(4, (i) {
        final active = i < strength;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: EdgeInsets.only(right: i < 3 ? 5 : 0),
            height: 3,
            decoration: BoxDecoration(
              color: active ? _colors[strength] : Colors.white24,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        );
      }),
    );
  }
}

class _StrengthLabel extends StatelessWidget {
  const _StrengthLabel({required this.strength});
  final int strength;

  static const _labels = ['', 'Faible', 'Correct', 'Bon', 'Fort'];
  static const _colors = [
    Colors.transparent,
    Color(0xFFE24B4A),
    Color(0xFFEF9F27),
    Color(0xFF1D9E75),
    Color(0xFF7F77DD),
  ];

  @override
  Widget build(BuildContext context) {
    return Text(
      _labels[strength],
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 0.1,
        color: _colors[strength],
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// ── Hint correspondance ──────────────────────────────────────────────────────

class _MatchHint extends StatelessWidget {
  const _MatchHint({required this.matches});
  final bool matches;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Row(
        key: ValueKey(matches),
        children: [
          Icon(
            matches ? Icons.check_circle_outline : Icons.highlight_off_outlined,
            size: 14,
            color: matches ? const Color(0xFF1D9E75) : const Color(0xFFE24B4A),
          ),
          const SizedBox(width: 6),
          Text(
            matches
                ? 'Les mots de passe correspondent'
                : 'Les mots de passe ne correspondent pas',
            style: TextStyle(
              fontSize: 12,
              color: matches ? const Color(0xFF1D9E75) : const Color(0xFFE24B4A),
            ),
          ),
        ],
      ),
    );
  }
}
