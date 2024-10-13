const request = require('supertest');
const app = require('../../../../app');
const { User, sequelize } = require('../../../models');

describe('Authentication Routes', () => {
    let user;

    beforeAll(async () => {
        user = {
            username: 'testuser',
            email: 'testuser@example.com',
            password: 'Password123!',
        };
        await request(app).post('/api/auth/signup').send(user);
    });

    afterEach(() => {
        jest.clearAllTimers();
        jest.resetModules();
        jest.resetAllMocks();
    });

    afterAll(async () => {
        await User.destroy({ where: {} });
        if(sequelize) {
            await sequelize.close(); 
        }
    });

    it('User should sign up successfully (unique email)', async () => {
        // Vérifier qu'on ne peut pas créer un utilisateur avec un email déjà utilisé
        const response = await request(app)
            .post('/api/auth/signup')
            .send({
                username: 'newuser',
                email: 'testuser@example.com', // Email déjà utilisé
                password: 'Password123!',
            });

        expect(response.status).toBe(500); // Conflit
        expect(response.body).toHaveProperty('message', 'L\'adresse email est déjà utilisé');
    });

    it('User should log in successfully', async () => {
        const response = await request(app)
            .post('/api/auth/login')
            .send({
                identifier: user.email,
                password: user.password,
            });
        expect(response.status).toBe(200);
        expect(response.body).toHaveProperty('token');
        expect(response.body).toHaveProperty('user');
    });

    it('User should logout successfully', async () => {
        const loginResponse = await request(app)
            .post('/api/auth/login')
            .send({
                identifier: user.email,
                password: user.password,
            });

        expect(loginResponse.status).toBe(200);
        const token = loginResponse.body.token;

        const response = await request(app)
            .post('/api/auth/logout')
            .set('Cookie', `token=${token}`);

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