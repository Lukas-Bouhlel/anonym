const request = require('supertest');
const app = require('../../../../app');
const { User, sequelize } = require('../../../models');
const { cleanupAuthData, createUser, login, strongPassword } = require('../../testUtils');

describe('Authentication Routes', () => {
    const user = {
        username: 'testuser',
        email: 'testuser@example.com',
        password: strongPassword,
    };
    let createdUser;

    beforeAll(async () => {
        await cleanupAuthData();
        await User.destroy({ where: {} });
        createdUser = await createUser(user);
    });

    afterEach(() => {
        jest.clearAllTimers();
        jest.resetModules();
        jest.resetAllMocks();
    });

    afterAll(async () => {
        await cleanupAuthData();
        await User.destroy({ where: {} });
        if (sequelize) {
            await sequelize.close();
        }
    });

    it('POST /api/auth/signup should expose the deprecated registration route', async () => {
        const response = await request(app)
            .post('/api/auth/signup')
            .send({
                username: 'newuser',
                email: 'newuser@example.com',
                password: strongPassword,
            });

        expect(response.status).toBe(410);
        expect(response.body).toHaveProperty(
            'message',
            "Cette route n'est plus disponible. Utilisez /auth/register/request-code puis /auth/register/confirm."
        );
    });

    it('User should log in successfully', async () => {
        const { response } = await login(app, user.email, user.password);

        expect(response.status).toBe(200);
        expect(response.body).toHaveProperty('token');
        expect(response.body).toHaveProperty('user');
        expect(response.body.user.id).toBe(createdUser.id);
    });

    it('User should logout successfully', async () => {
        const auth = await login(app, user.email, user.password);
        expect(auth.response.status).toBe(200);

        const response = await request(app)
            .post('/api/auth/logout')
            .set('Cookie', auth.cookieHeader)
            .set('x-csrf-token', auth.csrfToken);

        expect(response.status).toBe(200);
        expect(response.body).toHaveProperty('message', 'Successfully logged out');

        const cookies = response.headers['set-cookie'];
        expect(cookies).toBeDefined();
        expect(cookies[0]).toMatch(/token=;/);
    });

    it('User should request password reset', async () => {
        const response = await request(app)
            .post('/api/auth/reset-password')
            .send({
                email: user.email,
            });

        expect(response.status).toBe(200);
        expect(response.body).toHaveProperty('message', 'Email envoyé pour la réinitialisation de votre mot de passe');
    });
});
