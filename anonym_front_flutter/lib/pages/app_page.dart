import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_providers.dart';
import '../routes/app_router.dart';
import '../theme.dart';

/// Widget racine de l'application (MaterialApp + router).
class AnonymApp extends StatefulWidget {
  const AnonymApp({super.key});

  @override
  State<AnonymApp> createState() => _AnonymAppState();
}

class _AnonymAppState extends State<AnonymApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _router = buildRouter(authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Anonym',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      builder: (context, child) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: AppGradients.gB1BCFBTo393566,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: _router,
    );
  }
}
