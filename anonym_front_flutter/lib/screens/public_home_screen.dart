import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routes/app_routes.dart';

class PublicHomeScreen extends StatelessWidget {
  const PublicHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anonym')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Le réseau social qui protège tes données',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Base Flutter créée depuis ton front React. Tu peux maintenant migrer écran par écran.',
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go(AppRoutes.login),
            child: const Text('Se connecter'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.go(AppRoutes.register),
            child: const Text('Créer un compte'),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _navChip(context, 'Discover', AppRoutes.discover),
              _navChip(context, 'Reputation', AppRoutes.reputation),
              _navChip(context, 'Support', AppRoutes.support),
              _navChip(context, 'Legal', AppRoutes.legalNotices),
              _navChip(context, 'Privacy', AppRoutes.privacyPolicy),
              _navChip(context, 'Terms', AppRoutes.termsConditions),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navChip(BuildContext context, String label, String route) {
    return ActionChip(label: Text(label), onPressed: () => context.go(route));
  }
}
