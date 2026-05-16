import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';

import 'app_routes.dart';
import '../providers/auth_controller.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/reset_password_screen.dart';
import '../screens/placeholder_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/app_shell_screen.dart';
import '../screens/public_home_screen.dart';
import '../screens/payment_success_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/support_screen.dart';

GoRouter buildRouter(AuthController authController) {
  return GoRouter(
    initialLocation: AppRoutes.root,
    refreshListenable: authController,
    redirect: (context, state) {
      if (kDebugMode) {
        debugPrint(
          '[ROUTER][redirect:start] uri=${state.uri} matched=${state.matchedLocation} '
          'loggedIn=${authController.isLoggedIn} boot=${authController.isBootstrapping}',
        );
      }

      if (state.uri.path == '${AppRoutes.resetPassword}/') {
        final query = state.uri.hasQuery ? '?${state.uri.query}' : '';
        if (kDebugMode) {
          debugPrint(
            '[ROUTER][redirect] normalize trailing slash -> ${AppRoutes.resetPassword}$query',
          );
        }
        return '${AppRoutes.resetPassword}$query';
      }

      final location = state.matchedLocation;
      final isPrivate =
          location == AppRoutes.home ||
          location.startsWith('${AppRoutes.home}/') ||
          location == AppRoutes.profile ||
          location == AppRoutes.admin;
      final isResetRoute =
          location == AppRoutes.resetPassword ||
          location == '${AppRoutes.resetPassword}/';
      final isAuthFlow =
          location == AppRoutes.auth ||
          location == AppRoutes.login ||
          location == AppRoutes.register ||
          isResetRoute;

      if (authController.isBootstrapping) {
        if (kDebugMode) {
          debugPrint(
            '[ROUTER][redirect] bootstrapping -> ${location == AppRoutes.loading ? 'stay' : AppRoutes.loading}',
          );
        }
        return location == AppRoutes.loading ? null : AppRoutes.loading;
      }

      if (!authController.isLoggedIn && isPrivate) {
        if (kDebugMode) {
          debugPrint('[ROUTER][redirect] unauth private -> ${AppRoutes.auth}');
        }
        return AppRoutes.auth;
      }

      if (authController.isLoggedIn && isAuthFlow) {
        if (kDebugMode) {
          debugPrint(
            '[ROUTER][redirect] auth on auth-flow -> ${AppRoutes.app}',
          );
        }
        return AppRoutes.app;
      }

      if (authController.isLoggedIn && location == AppRoutes.root) {
        if (kDebugMode) {
          debugPrint('[ROUTER][redirect] auth on root -> ${AppRoutes.app}');
        }
        return AppRoutes.app;
      }

      if (!authController.isLoggedIn && location == AppRoutes.root) {
        if (kDebugMode) {
          debugPrint('[ROUTER][redirect] unauth on root -> ${AppRoutes.auth}');
        }
        return AppRoutes.auth;
      }

      if (location == AppRoutes.loading) {
        if (kDebugMode) {
          debugPrint(
            '[ROUTER][redirect] leave loading -> ${authController.isLoggedIn ? AppRoutes.app : AppRoutes.home}',
          );
        }
        return authController.isLoggedIn ? AppRoutes.app : AppRoutes.auth;
      }

      if (kDebugMode) {
        debugPrint('[ROUTER][redirect] allow (null)');
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.loading,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.root,
        redirect: (context, state) =>
            authController.isLoggedIn ? AppRoutes.app : AppRoutes.auth,
      ),
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const PublicHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.discover,
        builder: (context, state) => const PlaceholderScreen(title: 'Discover'),
      ),
      GoRoute(
        path: AppRoutes.reputation,
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Reputation'),
      ),
      GoRoute(
        path: AppRoutes.support,
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: AppRoutes.legalNotices,
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Legal notices'),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Privacy policy'),
      ),
      GoRoute(
        path: AppRoutes.termsConditions,
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Terms & conditions'),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) =>
            ResetPasswordScreen(token: state.uri.queryParameters['token']),
      ),
      GoRoute(
        path: AppRoutes.app,
        builder: (context, state) => const AppShellScreen(),
      ),
      GoRoute(
        path: AppRoutes.appSuccess,
        builder: (context, state) => PaymentSuccessScreen(
          sessionId: state.uri.queryParameters['session_id'],
        ),
      ),
      GoRoute(path: AppRoutes.legacyApp, redirect: (_, state) => AppRoutes.app),
      GoRoute(
        path: AppRoutes.legacyAppSuccess,
        redirect: (_, state) {
          final query = state.uri.hasQuery ? '?${state.uri.query}' : '';
          return '${AppRoutes.appSuccess}$query';
        },
      ),
      GoRoute(
        path: AppRoutes.legacyLogin,
        redirect: (_, state) => AppRoutes.login,
      ),
      GoRoute(
        path: AppRoutes.legacyRegister,
        redirect: (_, state) => AppRoutes.register,
      ),
      GoRoute(
        path: AppRoutes.legacyResetPassword,
        redirect: (_, state) {
          final query = state.uri.hasQuery ? '?${state.uri.query}' : '';
          return '${AppRoutes.resetPassword}$query';
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        builder: (context, state) => const PlaceholderScreen(title: 'Admin'),
      ),
    ],
  );
}
