const request = require('supertest');
const app = require('../../../../app');
const { User, sequelize } = require('../../../models');

describe('Admin Routes', () => {
    let adminToken;
    let regularToken;
    let createdUserId;

    const adminUser = {
        username: 'adminusertest',
        email: 'adminusertest@example.com',
        password: 'Password123!',
        roles: 'ADMIN',
    };

    const regularUser = {
        username: 'regularusertest',
        email: 'regularusertest@example.com',
        password: 'Password123!',
        roles: 'USER',
    };

    beforeAll(async () => {
        // Création des utilisateurs admin et régulier
        await User.create(adminUser);
        await User.create(regularUser);

        // Connexion en tant qu'admin pour obtenir le token
        const adminResponse = await request(app)
            .post('/api/auth/login')
            .send({
                identifier: adminUser.username,
                password: adminUser.password,
            });
        adminToken = adminResponse.body.token;

        // Connexion en tant qu'utilisateur régulier pour obtenir le token
        const userResponse = await request(app)
            .post('/api/auth/login')
            .send({
                identifier: regularUser.username,
                password: regularUser.password,
            });
        regularToken = userResponse.body.token;
    });
    
    afterEach(() => {
        jest.clearAllMocks(); // Nettoyer les mocks après chaque test
        jest.resetModules();
    });

    afterAll(async () => {
        await User.destroy({ where: {} });
        await sequelize.close(); // Fermer la connexion à la base de données après tous les tests
    });

    // Test: Admin crée un nouvel utilisateur
    // it('should allow admin to create a new user', async () => {
    //     const newUser = {
    //         datas: JSON.stringify({
    //             username: 'JohnDoe',
    //             email: 'JohnDoe@example.com',
    //             password: 'Password123!',
    //             roles: 'USER',
    //         })
    //     };

    //     const response = await request(app)
    //         .post('/api/admin/users')
    //         .set('Cookie', `token=${adminToken}`) // Utilisation du token admin via les cookies
    //         .send(newUser);
    //     console.log(newUser)
    //     console.log("REPONSE : " + response)

    //     expect(response.status).toBe(201); // Créé
    //     expect(response.body).toHaveProperty('username', 'JohnDoe');
    //     createdUserId = response.body.id; // Stocker l'ID de l'utilisateur créé pour les tests suivants
    // });

    // Test: Un utilisateur régulier ne peut pas créer un utilisateur
    it('should not allow regular users to create a new user', async () => {
        const newUser = {
            datas: JSON.stringify({
                username: 'unauthuser',
                email: 'unauthuser@example.com',
                password: 'Password123!',
                roles: 'USER',
            })
        };

        const response = await request(app)
            .post('/api/admin/users')
            .set('Cookie', `token=${regularToken}`) // Utilisation du token utilisateur régulier
            .send(newUser);

        expect(response.status).toBe(403); // Interdit
        expect(response.body.message).toBe('You do not have permission to create a user.'); // Message d'erreur cohérent
    });

    // Test: Admin met à jour un utilisateur existant
    // it('should allow admin to update an existing user', async () => {
    //     const updateData = {
    //         datas: JSON.stringify({
    //             username: 'testJohnUpdate',
    //             roles: 'USER'
    //         })
    //     };

    //     const response = await request(app)
    //         .put(`/api/admin/users/${createdUserId}`)
    //         .set('Cookie', `token=${adminToken}`) // Token de l'admin via cookie
    //         .send(updateData);

    //     expect(response.status).toBe(200); // OK
    //     expect(response.body).toHaveProperty('username', 'testJohnUpdate');
    // });

    // Test: Un utilisateur régulier ne peut pas mettre à jour un autre utilisateur
    it('should not allow regular users to update a user', async () => {
        const updateData = {
            datas: JSON.stringify({
                username: 'shouldfailupdate',
                email: 'shouldfail@example.com',
            })
        };

        const response = await request(app)
            .put(`/api/admin/users/${createdUserId}`)
            .set('Cookie', `token=${regularToken}`) // Token de l'utilisateur régulier
            .send(updateData);

        expect(response.status).toBe(403); // Interdit
        expect(response.body.message).toBe('Il faut être admin pour accéder à cette page.');
    });

    // Test: Admin supprime un utilisateur
    // it('should allow admin to delete an existing user', async () => {
    //     const response = await request(app)
    //         .delete(`/api/admin/users/${createdUserId}`)
    //         .set('Cookie', `token=${adminToken}`); // Token de l'admin via cookie

    //     expect(response.status).toBe(200); // OK
    //     expect(response.body.message).toBe('User deleted successfully.');
    // });
});
