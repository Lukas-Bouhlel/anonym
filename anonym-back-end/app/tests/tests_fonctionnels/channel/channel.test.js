const request = require('supertest');
const app = require('../../../../app'); // Chemin vers votre fichier app.js
const { User, Channel, UserChannel, sequelize } = require('../../../models');

describe('Channel Routes', () => {
    let user;
    let token; // Token JWT pour l'utilisateur
    let channelId;
    
    beforeAll(async () => {
        // Créer un utilisateur de test
        const userCreate = {
            username: 'testchannel',
            email: 'testchannel@example.com',
            password: 'Password123!',
        };

        user = await User.create(userCreate); // Créer l'utilisateur dans la base de données

        // Créer un canal de test
        const channel = await Channel.create({
            name: 'Test Channel',
            description: 'This is a test channel',
            created_by: user.dataValues.id
        });
        channelId = channel.channel_id;

        const response = await request(app)
        .post('/api/auth/login') // Point de terminaison d'authentification
        .send({
            identifier: user.dataValues.email, // Utiliser le nom d'utilisateur
            password: 'Password123!', // Mot de passe de l'utilisateur
        });

        token = response.body.token; // Récupérer le token

        await UserChannel.create({
            user_id: user.dataValues.id,
            channel_id: channelId,
        });
    });

    afterEach(() => {
        jest.clearAllTimers(); // Nettoyer tous les timers
        jest.resetModules();
    });

    afterAll(async () => {
        await User.destroy({ where: {} });
        await UserChannel.destroy({ where: {} });
        await Channel.destroy({ where: {} });
        await sequelize.close(); // Fermer la connexion à la base de données
    });

    // Connexion pour obtenir le token JWT avant chaque test
    beforeEach(async () => {

    });

    test('User should create a channel successfully', async () => {
        const response = await request(app)
            .post('/api/channels')
            .set('Cookie', `token=${token}`)
            .send({
                name: 'New Channel',
                description: 'A new test channel'
            });

        expect(response.status).toBe(201);
        expect(response.body).toHaveProperty('name', 'New Channel');
        expect(response.body).toHaveProperty('description', 'A new test channel');
        expect(response.body).toHaveProperty('created_by', user.dataValues.id);
    });

    test('User should receive 400 error if channel name is missing', async () => {
        const response = await request(app)
            .post('/api/channels')
            .set('Cookie', `token=${token}`)
            .send({
                description: 'A channel without a name'
            });

        expect(response.status).toBe(400);
        expect(response.body).toHaveProperty('message', 'Le nom du groupe est requis');
    });

    test('User should invite another user to a channel successfully', async () => {
        const newUser = await User.create({
            username: 'inviteuser',
            email: 'inviteuser@example.com',
            password: 'Password123!'
        });

        const response = await request(app)
            .post('/api/channels/invite')
            .set('Cookie', `token=${token}`)
            .send({
                channelId: channelId,
                userId: newUser.dataValues.id
            });

        expect(response.status).toBe(200);
        expect(response.body).toHaveProperty('message', 'Utilisateur ajouté au canal avec succès.');
    });

    test('User should receive 400 error if trying to invite an existing member', async () => {
        const response = await request(app)
            .post('/api/channels/invite')
            .set('Cookie', `token=${token}`)
            .send({
                channelId: channelId,
                userId: user.dataValues.id 
            });

        expect(response.status).toBe(400);
        expect(response.body).toHaveProperty('message', 'Cet utilisateur est déjà membre de ce canal.');
    });

    test('User should get their channels successfully', async () => {
        const response = await request(app)
            .get('/api/channels/user')
            .set('Cookie', `token=${token}`)

        expect(response.status).toBe(200);
        expect(response.body).toBeInstanceOf(Array);
        // expect(response.body[0]).toHaveProperty('channel_id', channelId);
        // expect(response.body[0]).toHaveProperty('name', 'Test Channel');
    });

    test('User should get unread message count successfully', async () => {
        const response = await request(app)
            .get(`/api/channels/${channelId}/unreadCount`)
            .set('Cookie', `token=${token}`)

        expect(response.status).toBe(200);
        expect(response.body).toHaveProperty('count');
    });

    test('User should leave a channel successfully', async () => {
        const response = await request(app)
            .delete(`/api/channels/leave/${channelId}`)
            .set('Cookie', `token=${token}`)

        expect(response.status).toBe(200);
        expect(response.body).toHaveProperty('message', 'Vous avez quitté le canal avec succès.');
    });

    test('User should delete their channel successfully', async () => {
        const response = await request(app)
            .delete(`/api/channels/${channelId}`)
            .set('Cookie', `token=${token}`)

        expect(response.status).toBe(200);
        expect(response.body).toHaveProperty('message', 'Canal supprimé avec succès.');
    });

    test('User should receive 404 error if channel does not exist on delete', async () => {
        const response = await request(app)
            .delete(`/api/channels/non-existent-id`)
            .set('Cookie', `token=${token}`)

        expect(response.status).toBe(404);
        expect(response.body).toHaveProperty('message', 'Canal non trouvé.');
    });
});