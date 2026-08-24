import {
  buildMobileResetDeepLink,
  shouldOpenMobileResetApp
} from '../../src/utils/resetPasswordLinks';

describe('reset password mobile links', () => {
  it('builds an encoded application link from the reset token', () => {
    expect(buildMobileResetDeepLink(' token/with spaces ')).toBe(
      'anonym:///auth/reset?token=token%2Fwith%20spaces'
    );
  });

  it('opens the app only for the mobile-specific HTTPS reset route', () => {
    expect(shouldOpenMobileResetApp({
      pathname: '/auth/reset',
      userAgent: 'Mozilla/5.0 (Linux; Android 15)',
      token: 'abc123'
    })).toBe(true);

    expect(shouldOpenMobileResetApp({
      pathname: '/reset',
      userAgent: 'Mozilla/5.0 (Linux; Android 15)',
      token: 'abc123'
    })).toBe(false);
  });

  it('keeps desktop browsers on the web reset page', () => {
    expect(shouldOpenMobileResetApp({
      pathname: '/auth/reset',
      userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
      token: 'abc123'
    })).toBe(false);
  });
});
