const {
    PrivateMessage,
    User,
    Inventory,
    Shop,
    Channel,
    UserChannel,
    Friend,
    UserPointDaily,
    sequelize
} = require('../models');
const { Op } = require('sequelize');
const { deleteUploadFiles } = require('./fileCleanup');
const { sendPushToUsers } = require('./pushNotifications');
let hasAllowNonFriendDmsColumnCache = null;
const activePresenceConnections = new Map();
const liveLocationsByUserId = new Map();

const incrementPresenceConnections = (userId) => {
    const key = String(userId);
    const current = activePresenceConnections.get(key) || 0;
    activePresenceConnections.set(key, current + 1);
};

const decrementPresenceConnections = (userId) => {
    const key = String(userId);
    const current = activePresenceConnections.get(key) || 0;
    if (current <= 1) {
        activePresenceConnections.delete(key);
        return 0;
    }
    activePresenceConnections.set(key, current - 1);
    return current - 1;
};

const toInt = (value) => {
    if (typeof value === 'number' && Number.isFinite(value)) {
        return Math.trunc(value);
    }
    if (typeof value === 'string') {
        const parsed = parseInt(value, 10);
        return Number.isFinite(parsed) ? parsed : 0;
    }
    return 0;
};

const toFiniteNumber = (value) => {
    if (typeof value === 'number') {
        return Number.isFinite(value) ? value : NaN;
    }
    if (typeof value === 'string' && value.trim().length > 0) {
        const parsed = Number.parseFloat(value);
        return Number.isFinite(parsed) ? parsed : NaN;
    }
    return NaN;
};

const normalizeAvatar = (value) => {
    if (typeof value !== 'string') return null;
    const trimmed = value.trim();
    return trimmed.length > 0 ? trimmed : null;
};

const normalizeUsername = (value) => {
    if (typeof value !== 'string') return '';
    return value.trim();
};

const normalizeLocationPayload = (rawPayload, fallback = {}) => {
    const source = rawPayload && typeof rawPayload === 'object'
        ? rawPayload
        : {};
    const fallbackSource = fallback && typeof fallback === 'object'
        ? fallback
        : {};

    const userId = toInt(source.userId ?? source.user_id ?? source.id ?? fallbackSource.userId);
    if (userId <= 0) return null;

    const latitude = toFiniteNumber(
        source.lat ?? source.latitude ?? source.y ?? source.position?.lat
    );
    const longitude = toFiniteNumber(
        source.lng ?? source.lon ?? source.longitude ?? source.x ?? source.position?.lng ?? source.position?.lon
    );

    if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
        return null;
    }
    if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
        return null;
    }

    const username = normalizeUsername(
        source.username ?? source.pseudo ?? fallbackSource.username
    ) || 'Utilisateur';
    const avatar = normalizeAvatar(source.avatar ?? fallbackSource.avatar);

    const updatedAtRaw = source.updatedAt ?? source.updated_at ?? source.timestamp;
    const parsedUpdatedAt = (() => {
        if (typeof updatedAtRaw === 'string' && updatedAtRaw.trim().length > 0) {
            const parsed = new Date(updatedAtRaw);
            return Number.isNaN(parsed.getTime()) ? null : parsed.toISOString();
        }
        if (typeof updatedAtRaw === 'number' && Number.isFinite(updatedAtRaw)) {
            const parsed = new Date(updatedAtRaw);
            return Number.isNaN(parsed.getTime()) ? null : parsed.toISOString();
        }
        return null;
    })();

    const accuracyRaw = toFiniteNumber(source.accuracy);

    return {
        userId,
        username,
        avatar,
        lat: latitude,
        lng: longitude,
        accuracy: Number.isFinite(accuracyRaw) ? accuracyRaw : null,
        updatedAt: parsedUpdatedAt || new Date().toISOString()
    };
};

const getActiveFriendIds = async (userId) => {
    const normalizedUserId = toInt(userId);
    if (normalizedUserId <= 0) return [];

    const rows = await Friend.findAll({
        where: {
            status: 'ACTIVE',
            [Op.or]: [
                { user_id: normalizedUserId },
                { friend_id: normalizedUserId }
            ]
        },
        attributes: ['user_id', 'friend_id'],
        raw: true
    });

    const ids = new Set();
    for (const row of rows) {
        const left = toInt(row.user_id);
        const right = toInt(row.friend_id);
        if (left === normalizedUserId && right > 0) {
            ids.add(right);
            continue;
        }
        if (right === normalizedUserId && left > 0) {
            ids.add(left);
        }
    }

    return [...ids];
};

const getLocationAudienceIds = async (userId, { includeSelf = true } = {}) => {
    const normalizedUserId = toInt(userId);
    if (normalizedUserId <= 0) return [];

    const audience = new Set();
    if (includeSelf) audience.add(normalizedUserId);

    const friendIds = await getActiveFriendIds(normalizedUserId);
    for (const friendId of friendIds) {
        if (friendId > 0) audience.add(friendId);
    }

    return [...audience];
};

const buildLocationSnapshotForViewer = async (viewerUserId) => {
    const allowedIds = await getLocationAudienceIds(viewerUserId, {
        includeSelf: true
    });

    const snapshot = [];
    for (const allowedUserId of allowedIds) {
        const location = liveLocationsByUserId.get(allowedUserId);
        if (!location) continue;
        snapshot.push(location);
    }
    return snapshot;
};

const emitLocationSnapshotToUser = async (socket, viewerUserId) => {
    const normalizedViewerId = toInt(viewerUserId);
    if (!socket || normalizedViewerId <= 0) return;

    try {
        const snapshot = await buildLocationSnapshotForViewer(normalizedViewerId);
        socket.emit('location:snapshot', snapshot);
    } catch (error) {
        console.error('[SOCKET][location] snapshot failed:', error.message);
    }
};

const emitLocationUpdateToAudience = async (io, sourceUserId) => {
    const normalizedSourceId = toInt(sourceUserId);
    if (normalizedSourceId <= 0) return;
    const payload = liveLocationsByUserId.get(normalizedSourceId);
    if (!payload) return;

    try {
        const audienceIds = await getLocationAudienceIds(normalizedSourceId, {
            includeSelf: true
        });
        for (const targetUserId of audienceIds) {
            io.to(`user:${targetUserId}`).emit('location:update', payload);
        }
    } catch (error) {
        console.error('[SOCKET][location] update emit failed:', error.message);
    }
};

const emitLocationRemoveToAudience = async (io, sourceUserId) => {
    const normalizedSourceId = toInt(sourceUserId);
    if (normalizedSourceId <= 0) return;

    try {
        const audienceIds = await getLocationAudienceIds(normalizedSourceId, {
            includeSelf: true
        });
        for (const targetUserId of audienceIds) {
            io.to(`user:${targetUserId}`).emit('location:remove', {
                userId: normalizedSourceId
            });
        }
    } catch (error) {
        console.error('[SOCKET][location] remove emit failed:', error.message);
    }
};

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

const hasBlockedRelationship = async (userAId, userBId) => {
    const blockedFriendship = await Friend.findOne({
        where: {
            status: 'BLOQUED',
            [Op.or]: [
                { user_id: userAId, friend_id: userBId },
                { user_id: userBId, friend_id: userAId }
            ]
        }
    });
    return Boolean(blockedFriendship);
};

const updateChannelReputationScore = async (channelId) => {
    const channel = await Channel.findByPk(channelId);
    if (!channel) return null;

    if (channel.channel_type !== 'GROUP' || channel.visibility !== 'PUBLIC') {
        if (channel.reputation_score !== 0) {
            await channel.update({ reputation_score: 0 });
        }
        return 0;
    }

    const [messageCount, participantCount] = await Promise.all([
        PrivateMessage.count({ where: { channel_id: channelId } }),
        UserChannel.count({ where: { channel_id: channelId } })
    ]);

    const reputationScore = (messageCount * 1) + (participantCount * 2);
    if (channel.reputation_score !== reputationScore) {
        await channel.update({ reputation_score: reputationScore });
    }
    return reputationScore;
};

const createMessageWithPoints = async ({
    senderId,
    channelId,
    content,
    imageUrl
}) => {
    let awardedPoints = 1;
    let appliedMultiplier = 1;
    let updatedTotalPoints = 0;

    const message = await sequelize.transaction(async (transaction) => {
        const activeItems = await Inventory.findAll({
            where: { user_id: senderId, active: true },
            include: [{
                model: Shop,
                attributes: ['points_multiplier']
            }],
            transaction
        });

        if (activeItems.length > 0) {
            appliedMultiplier = activeItems.reduce((accumulator, inventoryItem) => {
                const multiplier = Number(inventoryItem?.Shop?.points_multiplier || 1);
                if (!Number.isFinite(multiplier) || multiplier < 1) {
                    return accumulator;
                }

                return accumulator * multiplier;
            }, 1);
        }

        awardedPoints = Math.max(1, Math.round(1 * appliedMultiplier));

        const createdMessage = await PrivateMessage.create({
            sender_id: senderId,
            content,
            image_url: imageUrl,
            channel_id: channelId,
            status: 'unread',
            createdAt: new Date()
        }, { transaction });

        const user = await User.findByPk(senderId, {
            transaction,
            lock: transaction.LOCK.UPDATE
        });
        if (!user) {
            throw new Error('Expediteur introuvable.');
        }
        const nextTotalPoints = (user.total_points || 0) + awardedPoints;
        updatedTotalPoints = nextTotalPoints;
        user.total_points = nextTotalPoints;
        await user.save({ transaction });

        const currentDate = new Date().toISOString().slice(0, 10);
        const [dailyStat] = await UserPointDaily.findOrCreate({
            where: {
                user_id: senderId,
                stat_date: currentDate
            },
            defaults: {
                user_id: senderId,
                stat_date: currentDate,
                messages_count: 0,
                points_earned: 0
            },
            transaction
        });

        dailyStat.messages_count += 1;
        dailyStat.points_earned += awardedPoints;
        await dailyStat.save({ transaction });

        return createdMessage;
    });

    return {
        message,
        points: {
            awarded: awardedPoints,
            multiplier: Number(appliedMultiplier.toFixed(2)),
            total: updatedTotalPoints
        }
    };
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
        const connectedUserId = socket?.userId;
        console.log(`[SOCKET] connection socketId=${socket.id} userId=${connectedUserId || 'unknown'}`);

        if (connectedUserId) {
            socket.join(`user:${connectedUserId}`);
            console.log(`[SOCKET] join user room user:${connectedUserId} socketId=${socket.id}`);
            incrementPresenceConnections(connectedUserId);
            User.update(
                { presence_status: 'online' },
                { where: { id: connectedUserId } }
            ).then(() => {
                io.emit('presenceUpdated', {
                    userId: Number(connectedUserId),
                    presence_status: 'online'
                });
            }).catch((error) => {
                console.error('Error setting online presence:', error.message);
            });
        }

        socket.on('location:sync', async () => {
            if (!connectedUserId) return;
            await emitLocationSnapshotToUser(socket, connectedUserId);
        });

        socket.on('location:update', async (payload) => {
            if (!connectedUserId) return;
            const normalized = normalizeLocationPayload({
                ...(payload && typeof payload === 'object' ? payload : {}),
                userId: connectedUserId
            }, {
                userId: connectedUserId
            });
            if (!normalized) return;

            liveLocationsByUserId.set(normalized.userId, normalized);
            await emitLocationUpdateToAudience(io, normalized.userId);
        });

        socket.on('location:stop', async () => {
            if (!connectedUserId) return;
            const normalizedUserId = toInt(connectedUserId);
            if (normalizedUserId <= 0) return;

            const hadLocation = liveLocationsByUserId.delete(normalizedUserId);
            if (!hadLocation) return;
            await emitLocationRemoveToAudience(io, normalizedUserId);
        });

        socket.on('joinChannel', async (data) => {
            const { channelId } = data;
            const roomId = channelId.toString();
            console.log(`[SOCKET] joinChannel userId=${connectedUserId} channelId=${channelId}`);
            await markMessagesAsRead(channelId, connectedUserId);
            const unreadCount = await getUnreadMessageCount(channelId, connectedUserId);
            io.to(roomId).emit('unreadCount', { count: unreadCount });
            socket.join(roomId);
        });

        socket.on('privateMessage', async ({ content, channelId, imageUrl }) => {
            try {
                const senderId = Number(connectedUserId);
                const normalizedContent = typeof content === 'string' ? content.trim() : '';
                const normalizedImageUrl = typeof imageUrl === 'string' && imageUrl.trim().length > 0
                    ? imageUrl.trim()
                    : null;
                if (!normalizedContent && !normalizedImageUrl) {
                    socket.emit('messageError', { message: 'Le contenu ou une image est requis.' });
                    return;
                }

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
                    const blockedRelationshipExists = await hasBlockedRelationship(senderId, receiverId);
                    if (blockedRelationshipExists) {
                        socket.emit('messageError', { message: 'Impossible d envoyer un message: cette relation est bloquee.' });
                        return;
                    }

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

                const { message } = await createMessageWithPoints({
                    senderId,
                    channelId,
                    content: normalizedContent || null,
                    imageUrl: normalizedImageUrl
                });
                await updateChannelReputationScore(channelId);

                const sender = await User.findByPk(senderId, {
                    attributes: ['id', 'username', 'avatar', 'presence_status'],
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

                const messagePayload = {
                    id: message.message_id,
                    content: message.content,
                    imageUrl: message.image_url,
                    channelId,
                    senderId,
                    status: message.status,
                    sender,
                    createdAt: message.createdAt
                };

                if (channel.channel_type === 'PRIVATE_DM') {
                    for (const memberId of memberIds) {
                        io.to(`user:${memberId}`).emit('newMessage', messagePayload);
                    }
                } else {
                    io.to(channelId.toString()).emit('newMessage', messagePayload);
                }

                await sendPushToUsers({
                    userIds: memberIds,
                    excludeUserId: senderId,
                    data: {
                        event: 'newMessage',
                        id: message.message_id,
                        channelId,
                        senderId,
                        senderUsername: sender?.username || ''
                    }
                });

                const unreadCount = await getUnreadMessageCount(channelId, senderId);
                io.to(channelId.toString()).emit('unreadCount', { count: unreadCount });
            } catch (error) {
                console.error('Error sending private message:', error.message);
            }
        });

        socket.on('leaveChannel', async ({ channelId }) => {
            console.log(`[SOCKET] leaveChannel userId=${connectedUserId} channelId=${channelId}`);
            socket.leave(channelId.toString());
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
                io.to(channelId.toString()).emit('channelDeleted', channelId);
            } catch (error) {
                console.error('Error deleting channel:', error.message);
            }
        });

        socket.on('disconnect', async () => {
            if (connectedUserId) {
                const remainingConnections = decrementPresenceConnections(connectedUserId);
                if (remainingConnections === 0) {
                    const normalizedUserId = toInt(connectedUserId);
                    const hadLocation = liveLocationsByUserId.delete(normalizedUserId);
                    if (hadLocation) {
                        await emitLocationRemoveToAudience(io, normalizedUserId);
                    }

                    User.findByPk(connectedUserId, { attributes: ['id', 'presence_status'] })
                        .then(async (user) => {
                            if (!user) return;

                            // Rule:
                            // - If user was auto-online, mark them offline when disconnected.
                            // - If user manually chose a status (idle/dnd/invisible), keep it.
                            if (user.presence_status === 'online') {
                                await user.update({ presence_status: 'invisible' });
                                io.emit('presenceUpdated', {
                                    userId: Number(connectedUserId),
                                    presence_status: 'offline'
                                });
                                return;
                            }

                            io.emit('presenceUpdated', {
                                userId: Number(connectedUserId),
                                presence_status: user.presence_status === 'invisible' ? 'offline' : user.presence_status
                            });
                        })
                        .catch((error) => {
                            console.error('Error updating disconnect presence:', error.message);
                        });
                }
            }
            console.log(`[SOCKET] disconnected socketId=${socket.id} userId=${connectedUserId || 'unknown'}`);
        });
    });
};

module.exports = initializeSocket;
