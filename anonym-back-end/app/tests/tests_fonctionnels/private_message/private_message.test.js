const request = require('supertest');
const app = require('../../../../app'); // Assurez-vous que ce chemin pointe vers votre fichier app.js
const { PrivateMessage, Channel, User, sequelize } = require('../../../models');

describe('Private Messages Routes', () => {
    let user, otherUser, token, messageId, channel;

    beforeAll(async () => {
        // Création des utilisateurs (sender et receiver)
        user = await User.create({
            username: 'senderuser',
            email: 'sender@example.com',
            password: 'Password123!',
            role: 'USER'
        });

        otherUser = await User.create({
            username: 'receiveruser',
            email: 'receiver@example.com',
            password: 'Password123!',
            role: 'USER'
        });

        channel = await Channel.create({ 
            name: 'General', 
            description: 'test', 
            created_by: user.dataValues.id 
        });

        // Connexion utilisateur (sender) pour récupérer le token
        const userResponse = await request(app)
            .post('/api/auth/login')
            .send({
                identifier: user.email,
                password: 'Password123!'
            });

        token = userResponse.body.token;

        // Création d'un message privé envoyé par "user"
        const privateMessage = await PrivateMessage.create({
            content: 'This is a private message',
            sender_id: user.dataValues.id,
            receiver_id: otherUser.dataValues.id,
            channel_id: channel.channel_id
        });

        messageId = privateMessage.message_id;
    });

    afterEach(() => {
        jest.clearAllTimers(); // Nettoyer les timers après chaque test
        jest.resetModules();
    });

    afterAll(async () => {
        await Channel.destroy({ where: {} });
        await PrivateMessage.destroy({ where: {} });
        await sequelize.close();
    });

    // Test pour mettre à jour un message
    test('User should update their private message successfully', async () => {
        const newContent = 'Updated message content';
        const response = await request(app)
            .put(`/api/privateMessage/${messageId}`)
            .set('Cookie', `token=${token}`)
            .send({ content: newContent });

        expect(response.status).toBe(200);
        expect(response.body).toHaveProperty('content', newContent);
        expect(response.body).toHaveProperty('message_id', messageId);
    });

    // Test pour essayer de mettre à jour un message d'un autre utilisateur
    test('User should not be able to update a message they did not send', async () => {
        // On va faire la requête avec un autre utilisateur
        const otherTokenResponse = await request(app)
            .post('/api/auth/login')
            .send({
                identifier: otherUser.email,
                password: 'Password123!'
            });
        
        const otherToken = otherTokenResponse.body.token;

        const response = await request(app)
            .put(`/api/privateMessage/${messageId}`)
            .set('Cookie', `token=${otherToken}`)
            .send({ content: 'Attempt to update another user\'s message' });

        expect(response.status).toBe(404); // Le message n'appartient pas à cet utilisateur
        expect(response.body).toHaveProperty('message', "Message not found or you're not the sender.");
    });

    // Test pour supprimer un message
    test('User should delete their private message successfully', async () => {
        const response = await request(app)
            .delete(`/api/privateMessage/${messageId}`)
            .set('Cookie', `token=${token}`);

        expect(response.status).toBe(200);
        expect(response.body).toHaveProperty('message', 'Message deleted successfully.');
    });

    // Test pour essayer de supprimer un message d'un autre utilisateur
    test('User should not be able to delete a message they did not send', async () => {
        // Créons un nouveau message par "otherUser"
        const privateMessage = await PrivateMessage.create({
            content: 'Another user\'s private message',
            sender_id: otherUser.id,
            receiver_id: user.id,
            channel_id: channel.channel_id
        });

        const response = await request(app)
            .delete(`/api/privateMessage/${privateMessage.message_id}`)
            .set('Cookie', `token=${token}`);

        expect(response.status).toBe(404); // Le message n'appartient pas à cet utilisateur
        expect(response.body).toHaveProperty('message', "Message not found or you're not the sender.");
    });
});
