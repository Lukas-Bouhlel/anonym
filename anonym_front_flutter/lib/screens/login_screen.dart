import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_controller.dart';
import '../routes/app_routes.dart';
import '../validators/auth_validators.dart';
import '../widgets/centered_form.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthController>();
    final success = await auth.login(
      identifier: _identifierController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      context.go(AppRoutes.app);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Connexion impossible')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: CenteredForm(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _identifierController,
                decoration: const InputDecoration(
                  labelText: 'Email ou username',
                ),
                validator: (value) =>
                    AuthValidators.requiredField(value, label: 'Identifiant'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mot de passe'),
                validator: AuthValidators.password,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: auth.isBusy ? null : _submit,
                child: Text(auth.isBusy ? 'Connexion...' : 'Se connecter'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => context.go(AppRoutes.resetPassword),
                child: const Text('Mot de passe oublié ?'),
              ),
              TextButton(
                onPressed: () => context.go(AppRoutes.register),
                child: const Text('Créer un compte'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
