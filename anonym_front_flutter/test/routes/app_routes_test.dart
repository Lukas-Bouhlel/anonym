import 'package:anonym_front_flutter/routes/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppRoutes exposes stable core paths', () {
    expect(AppRoutes.root, '/');
    expect(AppRoutes.loading, '/loading');
    expect(AppRoutes.auth, '/auth');
    expect(AppRoutes.login, '/auth/login');
    expect(AppRoutes.register, '/auth/register');
    expect(AppRoutes.resetPassword, '/auth/reset');
    expect(AppRoutes.app, AppRoutes.home);
    expect(AppRoutes.appSuccess, '/home/success');
  });

  test('AppRoutes exposes legacy aliases for backward compatibility', () {
    expect(AppRoutes.legacyApp, '/app');
    expect(AppRoutes.legacyAppSuccess, '/app/success');
    expect(AppRoutes.legacyLogin, '/login');
    expect(AppRoutes.legacyRegister, '/register');
    expect(AppRoutes.legacyResetPassword, '/reset');
  });
}

