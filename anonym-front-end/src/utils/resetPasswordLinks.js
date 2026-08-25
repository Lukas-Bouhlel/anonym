const MOBILE_RESET_WEB_PATH = '/auth/reset';

export const buildMobileResetDeepLink = (token) => {
  const normalizedToken = typeof token === 'string' ? token.trim() : '';
  if (!normalizedToken) return '';

  return `anonym:///auth/reset?token=${encodeURIComponent(normalizedToken)}`;
};

export const shouldOpenMobileResetApp = ({ pathname, userAgent, token }) => {
  return pathname === MOBILE_RESET_WEB_PATH
    && buildMobileResetDeepLink(token) !== ''
    && /Android|iPhone|iPad|iPod/i.test(String(userAgent || ''));
};
