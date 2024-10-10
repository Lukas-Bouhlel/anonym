const request = require('supertest');
const app = require('../../../../app');
const { User, sequelize } = require('../../../models');

describe('Account Routes', () => {
    let token;
    let user;
    let userId;
    beforeAll(async () => {
        // Création de l'utilisateur
        user = {
            username: 'testaccount',
            email: 'testaccount@example.com',
            password: 'Password123!',
        };
        
        // Inscription de l'utilisateur
        await request(app).post('/api/auth/signup').send(user);

        // Vérification de l'ID utilisateur en base de données
        const createdUser = await User.findOne({ where: { email: user.email } });
        expect(createdUser).not.toBeNull();

        // Connexion pour obtenir un token
        const response = await request(app)
            .post('/api/auth/login')
            .send({
                identifier: user.username,
                password: user.password,
            });

        token = response.body.token; 
        userId = response.body.user.id;
    });

    afterEach(() => {
        jest.clearAllMocks(); // Nettoyer les mocks après chaque test
        jest.resetModules();
    });

    afterAll(async () => {
        await User.destroy({ where: {} }); // Nettoyer la base avant de commencer
        await sequelize.close(); // Fermer la connexion à la base de données après tous les tests
    });

    it('GET /api/account - should retrieve account info', async () => {
        const response = await request(app).get('/api/account').set('Cookie', `token=${token}`);
        expect(response.status).toBe(200);
        expect(response.body).toHaveProperty('username', user.username);
        expect(response.body).toHaveProperty('email', user.email);
    });

    it('GET /api/account/users - should retrieve all users', async () => {
        const response = await request(app)
            .get('/api/account/users')
            .set('Cookie', `token=${token}`); 

        expect(response.status).toBe(200);
        expect(Array.isArray(response.body)).toBe(true); // Vérifier que la réponse est un tableau
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
                }),
            });

        expect(response.status).toBe(200);
        expect(response.body).toHaveProperty('username', 'updateduser');
        expect(response.body).toHaveProperty('email', 'updated@example.com');
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