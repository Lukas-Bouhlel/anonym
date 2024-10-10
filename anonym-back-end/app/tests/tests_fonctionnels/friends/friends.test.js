const request = require('supertest');
const app = require('../../../../app');
const { User, Friend, sequelize } = require('../../../models');

let token;
let user;
let friendUser;
let newfriendUser;

describe('Friends Routes', () => {
    beforeAll(async () => {
        user = {
            username: 'testshop',
            email: 'testshop@example.com',
            password: 'Password123!',
        };
        friendUser = {
            username: 'frienduser',
            email: 'friend@example.com',
            password: 'Password123!',
        };
        newfriendUser = {
            username: 'newfriendUser',
            email: 'newfriendUser@example.com',
            password: 'Password123!',
        };
        
        // Création des utilisateurs
        await User.create(user);
        await User.create(friendUser);
        await User.create(newfriendUser);

        // Connexion pour obtenir un token
        const response = await request(app)
            .post('/api/auth/login')
            .send({
                identifier: user.username,
                password: user.password,
            });

        token = response.body.token; // Stocker le token pour les tests
    });

    afterEach(() => {
        jest.clearAllTimers(); // Nettoyer les timers après chaque test
        jest.resetModules();
    });

    afterAll(async () => {
        await User.destroy({ where: {} }); // Nettoyer la base de données
        await Friend.destroy({ where: {} }); // Nettoyer la base de données
        await sequelize.close(); // Fermer la connexion à la base de données après tous les tests
    });

    it('GET /api/friends - should retrieve all friends', async () => {
        const response = await request(app)
            .get('/api/friends')
            .set('Cookie', `token=${token}`);

        expect(response.status).toBe(200);
        expect(Array.isArray(response.body)).toBe(true);
    });

    it('GET /api/friends/:id - should retrieve a specific friend', async () => {
        // Ajout d'un ami
        const addFriendResponse = await request(app)
            .post('/api/friends/frienduser')
            .set('Cookie', `token=${token}`);

        expect(addFriendResponse.status).toBe(201);
        
        const friendId = addFriendResponse.body.friend_id;

        const response = await request(app)
            .get(`/api/friends/${friendId}`)
            .set('Cookie', `token=${token}`);

        expect(response.status).toBe(200);
        expect(response.body).toHaveProperty('friend_id', friendId);
    });

    it('POST /api/friends/:username - should add a friend', async () => {
        const response = await request(app)
            .post('/api/friends/newfriendUser')
            .set('Cookie', `token=${token}`);

        expect(response.status).toBe(201);
        expect(response.body).toHaveProperty('friend_id');
    });
});
