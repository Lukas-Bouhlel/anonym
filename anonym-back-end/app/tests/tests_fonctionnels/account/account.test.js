const request = require('supertest');
const app = require('../../../../app');
const { User, sequelize } = require('../../../models');
const { cleanupAuthData, createUser, login, strongPassword } = require('../../testUtils');

describe('Account Routes', () => {
    let token;
    let userId;
    const user = {
        username: 'testaccount',
        email: 'testaccount@example.com',
        password: strongPassword,
    };

    beforeAll(async () => {
        await cleanupAuthData();
        await User.destroy({ where: {} });

        const createdUser = await createUser(user);
        expect(createdUser).not.toBeNull();

        const { response } = await login(app, user.username, user.password);
        expect(response.status).toBe(200);

        token = response.body.token;
        userId = response.body.user.id;
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

    it('GET /api/account - should retrieve account info', async () => {
        const response = await request(app)
            .get('/api/account')
            .set('Cookie', `token=${token}`);

        expect(response.status).toBe(200);
        expect(response.body).toHaveProperty('username', user.username);
        expect(response.body).toHaveProperty('email', user.email);
    });

    it('GET /api/account/users - should reject non-admin users', async () => {
        const response = await request(app)
            .get('/api/account/users')
            .set('Cookie', `token=${token}`);

        expect(response.status).toBe(403);
        expect(response.body).toHaveProperty('message', 'Accès interdit, vous devez être Admin.');
    });

    it('GET /api/account/discoverable-users - should allow authenticated non-admin users', async () => {
        const response = await request(app)
            .get('/api/account/discoverable-users')
            .set('Cookie', `token=${token}`);

        expect(response.status).toBe(200);
        expect(Array.isArray(response.body)).toBe(true);
        expect(response.body[0]).toHaveProperty('username', user.username);
        expect(response.body[0]).not.toHaveProperty('password');
        expect(response.body[0]).not.toHaveProperty('email');
    });

    it('GET /api/account/:id - should retrieve user info by ID', async () => {
        const response = await request(app)
            .get(`/api/account/${userId}`)
            .set('Cookie', `token=${token}`);

        expect(response.status).toBe(200);
        expect(response.body).toHaveProperty('username', user.username);
    });

    it('PUT /api/account/update - should update user info', async () => {
        const response = await request(app)
            .put('/api/account/update')
            .set('Cookie', `token=${token}`)
            .send({
                datas: JSON.stringify({
                    username: 'updateduser',
                    email: 'updated@example.com',
                    bio: 'Bio de test',
                }),
            });

        expect(response.status).toBe(200);
        expect(response.body).toHaveProperty('username', 'updateduser');
        expect(response.body).toHaveProperty('email', 'updated@example.com');
        expect(response.body).toHaveProperty('bio', 'Bio de test');
    });

    it('PUT /api/account/password - should update user password', async () => {
        const response = await request(app)
            .put('/api/account/password')
            .set('Cookie', `token=${token}`)
            .send({
                currentPassword: user.password,
                newPassword: 'NewPassword123!',
                confirmNewPassword: 'NewPassword123!',
            });

        expect(response.status).toBe(200);
        expect(response.body).toHaveProperty('message', 'Mot de passe mis à jour avec succès.');
    });

    it('DELETE /api/account/delete - should delete user account', async () => {
        const response = await request(app)
            .delete('/api/account/delete')
            .set('Cookie', `token=${token}`);

        expect(response.status).toBe(200);
        expect(response.body).toHaveProperty('message', 'User deleted successfully');
    });
});
