/// Constantes de routes utilisées par le routeur de l'application.
class AppRoutes {
  const AppRoutes._();

  static const root = '/';
  static const loading = '/loading';

  static const auth = '/auth';
  static const home = '/home';
  static const discover = '/discover';
  static const reputation = '/reputation';
  static const support = '/support';
  static const legalNotices = '/legal-notices';
  static const privacyPolicy = '/privacy-policy';
  static const termsConditions = '/terms-conditions';

  static const login = '/auth/login';
  static const register = '/auth/register';
  static const resetPassword = '/auth/reset';

  static const app = home;
  static const appSuccess = '/home/success';
  static const profile = '/profile';
  static const admin = '/admin';

  // Legacy paths kept for backward compatibility with old bookmarks/deeplinks.
  static const legacyApp = '/app';
  static const legacyAppSuccess = '/app/success';
  static const legacyLogin = '/login';
  static const legacyRegister = '/register';
  static const legacyResetPassword = '/reset';
}
