const request = require('supertest');

const app = require('../../../app');

describe('reset password bridge', () => {
    const originalEnv = { ...process.env };

    beforeEach(() => {
        process.env.RESET_PASSWORD_WEB_URL = 'https://ano-nym.fr';
        process.env.RESET_PASSWORD_MOBILE_URL = 'https://www.ano-nym.fr';
        delete process.env.MOBILE_DEEP_LINK_BASE_URL;
    });

    afterEach(() => {
        process.env = { ...originalEnv };
    });

    it('redirects desktop browsers to the web reset page', async () => {
        const response = await request(app)
            .get('/open-reset-password?token=abc123')
            .set('user-agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)')
            .redirects(0);

        expect(response.status).toBe(302);
        expect(response.headers.location).toBe('https://ano-nym.fr/reset/?token=abc123');
    });

    it('opens the mobile deep link on mobile browsers with a web fallback', async () => {
        const response = await request(app)
            .get('/open-reset-password?token=abc123')
            .set('user-agent', 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)');

        expect(response.status).toBe(200);
        expect(response.text).toContain('https://www.ano-nym.fr/auth/reset?token=abc123');
        expect(response.text).toContain('https://ano-nym.fr/reset/?token=abc123');
    });
});
