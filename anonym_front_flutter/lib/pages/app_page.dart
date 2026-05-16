import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_controller.dart';
import '../routes/app_router.dart';
import '../theme.dart';

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
    final authController = context.read<AuthController>();
    _router = buildRouter(authController);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Anonym',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
