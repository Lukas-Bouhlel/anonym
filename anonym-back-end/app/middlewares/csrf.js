const crypto = require('crypto');

const ACCESS_COOKIE_NAME = process.env.JWT_ACCESS_COOKIE_NAME || 'token';
const REFRESH_COOKIE_NAME = process.env.JWT_REFRESH_COOKIE_NAME || 'refreshToken';
const CSRF_COOKIE_NAME = process.env.CSRF_COOKIE_NAME || 'csrfToken';

const getCookieOptions = () => ({
    httpOnly: false,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'Strict',
    maxAge: 7 * 24 * 60 * 60 * 1000,
});

const generateCsrfToken = () => crypto.randomBytes(32).toString('hex');

const ensureCsrfCookie = (req, res, next) => {
    if (!req.cookies?.[CSRF_COOKIE_NAME]) {
        res.cookie(CSRF_COOKIE_NAME, generateCsrfToken(), getCookieOptions());
    }
    next();
};

const requireCsrf = (req, res, next) => {
    const hasSessionCookie = Boolean(req.cookies?.[ACCESS_COOKIE_NAME] || req.cookies?.[REFRESH_COOKIE_NAME]);
    if (!hasSessionCookie) {
        return next();
    }

    const csrfCookie = req.cookies?.[CSRF_COOKIE_NAME];
    const csrfHeader = req.get('x-csrf-token') || req.get('X-CSRF-Token') || req.body?.csrfToken;

    if (!csrfCookie || !csrfHeader || csrfCookie !== csrfHeader) {
        return res.status(403).json({ message: 'CSRF token invalide ou manquant.' });
    }

    return next();
};

module.exports = {
    ensureCsrfCookie,
    requireCsrf,
    CSRF_COOKIE_NAME,
};
