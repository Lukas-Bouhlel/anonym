import 'package:flutter/material.dart';

import '../screens/app_shell_screen.dart';
import '../screens/login_screen.dart';
import '../screens/payment_success_screen.dart';
import '../screens/placeholder_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/public_home_screen.dart';
import '../screens/register_screen.dart';
import '../screens/reset_password_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/support_screen.dart';

/// Page de chargement/initialisation.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) => const SplashScreen();
}

/// Page d'accueil publique (non authentifiée).
class PublicHomePage extends StatelessWidget {
  const PublicHomePage({super.key});

  @override
  Widget build(BuildContext context) => const PublicHomeScreen();
}

/// Page de connexion.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) => const LoginScreen();
}

/// Page d'inscription.
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) => const RegisterScreen();
}

/// Page de réinitialisation de mot de passe.
class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key, this.token});

  final String? token;

  @override
  Widget build(BuildContext context) => ResetPasswordScreen(token: token);
}

/// Page shell principale de l'application authentifiée.
class AppShellPage extends StatelessWidget {
  const AppShellPage({super.key});

  @override
  Widget build(BuildContext context) => const AppShellScreen();
}

/// Page de retour de paiement.
class PaymentSuccessPage extends StatelessWidget {
  const PaymentSuccessPage({super.key, this.sessionId});

  final String? sessionId;

  @override
  Widget build(BuildContext context) =>
      PaymentSuccessScreen(sessionId: sessionId);
}

/// Page profil utilisateur courant.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) => const ProfileScreen();
}

/// Page de support.
class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) => const SupportScreen();
}

/// Page placeholder générique pour sections à compléter.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => PlaceholderScreen(title: title);
}
