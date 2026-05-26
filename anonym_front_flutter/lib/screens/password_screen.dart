import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_providers.dart';
import '../theme.dart';
import '../widgets/navigation/anonym_back_button.dart';

part '../widgets/password_screen_widgets.dart';

final RegExp _reLower = RegExp(r'[a-z]');
final RegExp _reUpper = RegExp(r'[A-Z]');
final RegExp _reDigit = RegExp(r'[0-9]');
final RegExp _reSpecial = RegExp(r"""[!@#\$%^&*()\-_=+\[\]{};'",.<>/?`~|\\]""");

class _Rule {
  const _Rule(this.label, this.test);
  final String label;
  final bool Function(String) test;
}

const List<_Rule> _passwordRules = [
  _Rule('Minimum 12 caractères', _checkLen),
  _Rule('Au moins 1 minuscule (a-z)', _checkLower),
  _Rule('Au moins 1 majuscule (A-Z)', _checkUpper),
  _Rule('Au moins 1 chiffre (0-9)', _checkDigit),
  _Rule('Au moins 1 caractère spécial', _checkSpecial),
];

bool _checkLen(String v) => v.length >= 12;
bool _checkLower(String v) => _reLower.hasMatch(v);
bool _checkUpper(String v) => _reUpper.hasMatch(v);
bool _checkDigit(String v) => _reDigit.hasMatch(v);
bool _checkSpecial(String v) => _reSpecial.hasMatch(v);

/// Écran de mise à jour du mot de passe.
class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _newTouched = false;
  bool _confirmTouched = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // Derived state

  bool _ruleOk(_Rule rule) => rule.test(_newController.text);
  bool get _allRulesOk => _passwordRules.every(_ruleOk);
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

  // Actions
  Future<void> _submit(BuildContext context, AppProvider app) async {
    await app.updatePassword(
      currentPassword: _currentController.text.trim(),
      newPassword: _newController.text.trim(),
      confirmNewPassword: _confirmController.text.trim(),
    );
    if (!context.mounted) return;
    if (app.errorMessage != null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Mot de passe mis à jour')));
    Navigator.of(context).pop();
  }

  // Build
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.gB1BCFBTo393566),
        child: SafeArea(
          child: Consumer<AppProvider>(
            builder: (context, app, _) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  // Header
                  Row(
                    children: [
                      const AnonymBackButton(),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Mot de passe',
                          style: t.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Mets à jour ton mot de passe en renseignant les champs ci-dessous.',
                    style: TextStyle(color: AppColors.cDBE7FE, fontSize: 14),
                  ),
                  const SizedBox(height: 22),

                  // Mot de passe actuel
                  _PasswordField(
                    controller: _currentController,
                    label: 'Mot de passe actuel',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // Nouveau mot de passe
                  AnimatedBuilder(
                    animation: _newController,
                    builder: (context, _) {
                      return _PasswordField(
                        controller: _newController,
                        label: 'Nouveau mot de passe',
                        hasError: _newTouched && !_allRulesOk,
                        isValid: _newTouched && _allRulesOk,
                        onChanged: (_) => setState(() {
                          _newTouched = true;
                        }),
                      );
                    },
                  ),

                  // Barre de force
                  if (_newTouched) ...[
                    const SizedBox(height: 10),
                    _StrengthBar(strength: _strength),
                    const SizedBox(height: 4),
                    _StrengthLabel(strength: _strength),
                  ],
                  const SizedBox(height: 10),

                  // Règles de validation
                  _ValidationRules(
                    rules: _passwordRules,
                    value: _newController.text,
                    touched: _newTouched,
                  ),
                  const SizedBox(height: 12),

                  // Confirmation 
                  AnimatedBuilder(
                    animation: _confirmController,
                    builder: (context, _) {
                      return _PasswordField(
                        controller: _confirmController,
                        label: 'Confirmation',
                        hasError: _confirmTouched && !_passwordsMatch,
                        isValid: _confirmTouched && _passwordsMatch,
                        onChanged: (_) => setState(() {
                          _confirmTouched = true;
                        }),
                      );
                    },
                  ),

                  // Hint correspondance
                  if (_confirmTouched &&
                      _confirmController.text.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _MatchHint(matches: _passwordsMatch),
                  ],
                  const SizedBox(height: 22),

                  // Bouton
                  FilledButton(
                    onPressed: (app.isSubmitting || !_canSubmit)
                        ? null
                        : () => _submit(context, app),
                    child: app.isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Mettre à jour'),
                  ),

                  // Erreur globale
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
