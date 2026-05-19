const { PrivateMessage, User, Inventory, Shop, Channel, UserChannel, Friend } = require('../models');
const { Op } = require('sequelize');
const { deleteUploadFiles } = require('./fileCleanup');
let hasAllowNonFriendDmsColumnCache = null;

const hasAllowNonFriendDmsColumn = async () => {
    if (hasAllowNonFriendDmsColumnCache !== null) {
        return hasAllowNonFriendDmsColumnCache;
    }

    try {
        const usersTable = await User.sequelize.getQueryInterface().describeTable('users');
        hasAllowNonFriendDmsColumnCache = Boolean(usersTable.allow_non_friend_dms);
    } catch {
        hasAllowNonFriendDmsColumnCache = false;
    }

    return hasAllowNonFriendDmsColumnCache;
};

const getUnreadMessageCount = async (channelId, userId) => {
    return await PrivateMessage.count({
        where: {
            channel_id: channelId,
            status: 'unread',
            sender_id: {
                [Op.ne]: userId
            }
        }
    });
};

const markMessagesAsRead = async (channelId, userId) => {
    return await PrivateMessage.update(
        { status: 'read' },
        {
            where: {
                channel_id: channelId,
                status: 'unread',
                sender_id: {
                    [Op.ne]: userId
                }
            }
        }
    );
};

const initializeSocket = (io) => {
    io.on('connection', (socket) => {
        socket.on('joinChannel', async (data) => {
            const { channelId, userId } = data;
            await markMessagesAsRead(channelId, userId);
            const unreadCount = await getUnreadMessageCount(channelId, userId);
            io.to(channelId).emit('unreadCount', { count: unreadCount });
            socket.join(channelId);
        });

        socket.on('privateMessage', async ({ senderId, content, channelId, imageUrl }) => {
            try {
                const channel = await Channel.findByPk(channelId);
                if (!channel) {
                    socket.emit('messageError', { message: 'Chat introuvable.' });
                    return;
                }

                const channelMembers = await UserChannel.findAll({
                    where: { channel_id: channelId },
                    attributes: ['user_id']
                });

                const memberIds = channelMembers.map((m) => m.user_id);
                if (!memberIds.includes(senderId)) {
                    socket.emit('messageError', { message: 'Vous ne faites pas partie de ce chat.' });
                    return;
                }

                if (channel.channel_type === 'PRIVATE_DM' && memberIds.length !== 2) {
                    socket.emit('messageError', { message: 'Configuration invalide pour un message prive.' });
                    return;
                }

                if (channel.channel_type === 'PRIVATE_DM') {
                    const receiverId = memberIds.find((id) => id !== senderId);
                    const allowNonFriendDmsColumnExists = await hasAllowNonFriendDmsColumn();
                    const receiver = await User.findByPk(receiverId, {
                        attributes: allowNonFriendDmsColumnExists ? ['id', 'allow_non_friend_dms'] : ['id']
                    });

                    if (!receiver) {
                        socket.emit('messageError', { message: 'Destinataire introuvable.' });
                        return;
                    }

                    const allowNonFriendDms = allowNonFriendDmsColumnExists
                        ? receiver.allow_non_friend_dms
                        : true;

                    if (!allowNonFriendDms) {
                        const acceptedFriendship = await Friend.findOne({
                            where: {
                                status: 'ACTIVE',
                                [Op.or]: [
                                    { user_id: senderId, friend_id: receiverId },
                                    { user_id: receiverId, friend_id: senderId }
                                ]
                            }
                        });

                        if (!acceptedFriendship) {
                            socket.emit('messageError', { message: 'Cet utilisateur refuse les messages prives des non-amis.' });
                            return;
                        }
                    }
                }

                const message = await PrivateMessage.create({
                    sender_id: senderId,
                    content,
                    image_url: imageUrl,
                    channel_id: channelId,
                    status: 'unread',
                    createdAt: new Date()
                });

                const sender = await User.findByPk(senderId, {
                    attributes: ['id', 'username', 'avatar'],
                    include: [
                        {
                            model: Inventory,
                            where: { active: true },
                            attributes: ['item_id', 'article_id', 'active'],
                            include: [
                                {
                                    model: Shop,
                                    attributes: ['title', 'type', 'content', 'amount']
                                }
                            ],
                            required: false
                        }
                    ]
                });

                io.to(channelId).emit('newMessage', {
                    id: message.message_id,
                    content: message.content,
                    imageUrl: message.image_url,
                    sender,
                    createdAt: message.createdAt
                });

                const unreadCount = await getUnreadMessageCount(channelId, senderId);
                io.to(channelId).emit('unreadCount', { count: unreadCount });
            } catch (error) {
                console.error('Error sending private message:', error.message);
            }
        });

        socket.on('leaveChannel', async ({ channelId }) => {
            socket.leave(channelId);
        });

        socket.on('deleteChannel', async (channelId) => {
            try {
                const channel = await Channel.findByPk(channelId, {
                    attributes: ['channel_id', 'cover_image']
                });
                if (channel) {
                    const messagesWithImages = await PrivateMessage.findAll({
                        where: {
                            channel_id: channelId,
                            image_url: { [Op.ne]: null }
                        },
                        attributes: ['image_url'],
                        raw: true
                    });

                    deleteUploadFiles([
                        channel.cover_image,
                        ...messagesWithImages.map((message) => message.image_url)
                    ]);
                }

                await Channel.destroy({ where: { channel_id: channelId } });
                io.to(channelId).emit('channelDeleted', channelId);
            } catch (error) {
                console.error('Error deleting channel:', error.message);
            }
        });

        socket.on('disconnect', () => {
            console.log(`Client disconnected: ${socket.id}`);
        });
    });
};

module.exports = initializeSocket;
