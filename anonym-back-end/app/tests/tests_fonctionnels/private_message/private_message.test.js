const request = require('supertest');
const app = require('../../../../app');
const { PrivateMessage, Channel, User, UserChannel, sequelize } = require('../../../models');
const { cleanupAuthData, createUser, login, strongPassword } = require('../../testUtils');

describe('Private Messages Routes', () => {
    let user;
    let otherUser;
    let token;
    let messageId;
    let channel;

    beforeAll(async () => {
        await cleanupAuthData();
        await PrivateMessage.destroy({ where: {} });
        await UserChannel.destroy({ where: {} });
        await Channel.destroy({ where: {} });
        await User.destroy({ where: {} });

        user = await createUser({
            username: 'senderuser',
            email: 'sender@example.com',
            password: strongPassword,
            roles: 'USER'
        });

        otherUser = await createUser({
            username: 'receiveruser',
            email: 'receiver@example.com',
            password: strongPassword,
            roles: 'USER'
        });

        channel = await Channel.create({
            name: 'General',
            description: 'test',
            channel_type: 'GROUP',
            visibility: 'PUBLIC',
            created_by: user.id
        });
        await UserChannel.bulkCreate([
            { channel_id: channel.channel_id, user_id: user.id },
            { channel_id: channel.channel_id, user_id: otherUser.id }
        ]);

        const userResponse = await login(app, user.email, strongPassword);
        expect(userResponse.response.status).toBe(200);
        token = userResponse.token;

        const privateMessage = await PrivateMessage.create({
            content: 'This is a private message',
            sender_id: user.id,
            channel_id: channel.channel_id
        });

        messageId = privateMessage.message_id;
    });

    afterEach(() => {
        jest.clearAllTimers();
        jest.resetModules();
        delete app.locals.io;
        app.set('io', null);
    });

    afterAll(async () => {
        await PrivateMessage.destroy({ where: {} });
        await UserChannel.destroy({ where: {} });
        await Channel.destroy({ where: {} });
        await cleanupAuthData();
        await User.destroy({ where: {} });
        if (sequelize) {
            await sequelize.close();
        }
    });

    test('User should update their private message successfully', async () => {
        const newContent = 'Updated message content';
        const emit = jest.fn();
        const to = jest.fn(() => ({ emit }));
        app.locals.io = { to };
        app.set('io', { to });

        const response = await request(app)
            .put(`/api/privateMessage/${messageId}`)
            .set('Cookie', `token=${token}`)
            .send({ content: newContent });

        expect(response.status).toBe(200);
        expect(response.body).toHaveProperty('content', newContent);
        expect(response.body).toHaveProperty('message_id', messageId);
        expect(to).toHaveBeenCalledWith(channel.channel_id.toString());
        expect(emit).toHaveBeenCalledWith(
            'messageUpdated',
            expect.objectContaining({
                id: messageId,
                content: newContent,
                channelId: channel.channel_id,
                senderId: user.id
            })
        );
    });

    test('User should not be able to update a message they did not send', async () => {
        const otherTokenResponse = await login(app, otherUser.email, strongPassword);
        expect(otherTokenResponse.response.status).toBe(200);

        const response = await request(app)
            .put(`/api/privateMessage/${messageId}`)
            .set('Cookie', `token=${otherTokenResponse.token}`)
            .send({ content: 'Attempt to update another user message' });

        expect(response.status).toBe(404);
        expect(response.body).toHaveProperty('message', "Message not found or you're not the sender.");
    });

    test('User should send an image message to channel and user rooms', async () => {
        const emit = jest.fn();
        const to = jest.fn(() => ({ emit }));
        app.locals.io = { to };
        app.set('io', { to });

        const response = await request(app)
            .post(`/api/privateMessage/${channel.channel_id}/send`)
            .set('Cookie', `token=${token}`)
            .field('content', 'image caption');

        expect(response.status).toBe(201);
        expect(response.body).toHaveProperty('channelId', channel.channel_id);
        expect(to).toHaveBeenCalledWith(channel.channel_id.toString());
        expect(to).toHaveBeenCalledWith(`user:${user.id}`);
        expect(to).toHaveBeenCalledWith(`user:${otherUser.id}`);
        expect(emit).toHaveBeenCalledWith(
            'newMessage',
            expect.objectContaining({
                content: 'image caption',
                channelId: channel.channel_id,
                senderId: user.id
            })
        );
    });

    test('User should delete their private message successfully', async () => {
        const emit = jest.fn();
        const to = jest.fn(() => ({ emit }));
        app.locals.io = { to };
        app.set('io', { to });

        const response = await request(app)
            .delete(`/api/privateMessage/${messageId}`)
            .set('Cookie', `token=${token}`);

        expect(response.status).toBe(200);
        expect(response.body).toHaveProperty('message', 'Message deleted successfully.');
        expect(to).toHaveBeenCalledWith(channel.channel_id.toString());
        expect(emit).toHaveBeenCalledWith(
            'messageDeleted',
            expect.objectContaining({
                messageId,
                channelId: channel.channel_id
            })
        );
    });

    test('User should not be able to delete a message they did not send', async () => {
        const privateMessage = await PrivateMessage.create({
            content: 'Another user private message',
            sender_id: otherUser.id,
            channel_id: channel.channel_id
        });

        const response = await request(app)
            .delete(`/api/privateMessage/${privateMessage.message_id}`)
            .set('Cookie', `token=${token}`);

        expect(response.status).toBe(404);
        expect(response.body).toHaveProperty('message', "Message not found or you're not the sender.");
    });
});
