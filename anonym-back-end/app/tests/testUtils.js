const request = require('supertest');
const {
    User,
    RefreshToken,
    RegisterVerificationCode,
    RegisterVerificationEvent
} = require('../models');

const strongPassword = 'Password123!';

const createUser = async (overrides = {}) => User.create({
    username: overrides.username || `user_${Date.now()}`,
    email: overrides.email || `user_${Date.now()}@example.com`,
    password: overrides.password || strongPassword,
    roles: overrides.roles || 'USER',
    avatar: overrides.avatar || null
});

const extractCookies = (response) => response.headers['set-cookie'] || [];

const getCookieValue = (cookies, name) => {
    const cookie = cookies.find((entry) => entry.startsWith(`${name}=`));
    return cookie ? cookie.split(';')[0].split('=').slice(1).join('=') : null;
};

const login = async (app, identifier, password = strongPassword) => {
    const response = await request(app)
        .post('/api/auth/login')
        .send({ identifier, password });

    const cookies = extractCookies(response);
    return {
        response,
        token: response.body?.token,
        refreshToken: getCookieValue(cookies, 'refreshToken'),
        csrfToken: getCookieValue(cookies, 'csrfToken'),
        cookieHeader: cookies.map((cookie) => cookie.split(';')[0]).join('; ')
    };
};

const cleanupAuthData = async () => {
    await RefreshToken.destroy({ where: {} });
    await RegisterVerificationCode.destroy({ where: {} });
    await RegisterVerificationEvent.destroy({ where: {} });
};

module.exports = {
    cleanupAuthData,
    createUser,
    login,
    strongPassword
};
