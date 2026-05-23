const { Op } = require('sequelize');
const { Friend, User, Inventory, Shop } = require('../models');
const { getLevelFromPoints } = require('../utils/points');
const { sendPushToUsers } = require('../utils/pushNotifications');

const FRIEND_STATUS = {
    ACTIVE: 'ACTIVE',
    PENDING: 'PENDING',
    BLOQUED: 'BLOQUED'
};

const friendDetailsInclude = {
    model: User,
    as: 'FriendDetails',
    attributes: ['id', 'username', 'email', 'avatar', 'total_points', 'presence_status', 'createdAt', 'updatedAt'],
    include: [
        {
            model: Inventory,
            where: { active: true },
            attributes: ['item_id', 'article_id', 'active'],
            include: [
                {
                    model: Shop,
                    where: { type: 'CADRE' },
                    attributes: ['title', 'type', 'content', 'amount']
                }
            ],
            required: false
        }
    ]
};

const getPresenceForViewer = (user, viewerId) => {
    const status = user?.presence_status || 'online';
    if (status === 'invisible' && Number(user?.id) !== Number(viewerId)) {
        return 'offline';
    }
    return status;
};

const addLevelToUser = (user, viewerId) => {
    if (!user) return user;
    const totalPoints = user.total_points || 0;
    const { total_points, ...userWithoutTotalPoints } = user;
    return {
        ...userWithoutTotalPoints,
        presence_status: getPresenceForViewer(user, viewerId),
        level: getLevelFromPoints(totalPoints)
    };
};

const addLevelToFriendRecord = (record, viewerId) => {
    const plain = record.toJSON ? record.toJSON() : record;

    if (plain.FriendDetails) {
        return {
            ...plain,
            FriendDetails: addLevelToUser(plain.FriendDetails, viewerId)
        };
    }

    if (plain.User) {
        return {
            ...plain,
            User: addLevelToUser(plain.User, viewerId)
        };
    }

    return plain;
};

exports.readAll = async (req, res) => {
    try {
        const userId = req.auth.userId;
        const friends = await Friend.findAll({
            where: { user_id: userId, status: FRIEND_STATUS.ACTIVE },
            include: [friendDetailsInclude]
        });

        res.status(200).json(friends.map((friend) => addLevelToFriendRecord(friend, userId)));
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while retrieving friends.' });
    }
};

exports.readIncomingRequests = async (req, res) => {
    try {
        const userId = req.auth.userId;
        const requests = await Friend.findAll({
            where: { friend_id: userId, status: FRIEND_STATUS.PENDING },
            include: [{
                model: User,
                as: 'User',
                attributes: ['id', 'username', 'email', 'avatar', 'total_points', 'presence_status']
            }],
            order: [['createdAt', 'DESC']]
        });

        res.status(200).json(requests.map((request) => addLevelToFriendRecord(request, userId)));
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while retrieving incoming requests.' });
    }
};

exports.readOutgoingRequests = async (req, res) => {
    try {
        const userId = req.auth.userId;
        const requests = await Friend.findAll({
            where: { user_id: userId, status: FRIEND_STATUS.PENDING },
            include: [friendDetailsInclude],
            order: [['createdAt', 'DESC']]
        });

        res.status(200).json(requests.map((request) => addLevelToFriendRecord(request, userId)));
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while retrieving outgoing requests.' });
    }
};

exports.readBlockedUsers = async (req, res) => {
    try {
        const userId = req.auth.userId;
        const blockedUsers = await Friend.findAll({
            where: { user_id: userId, status: FRIEND_STATUS.BLOQUED },
            include: [friendDetailsInclude],
            order: [['updatedAt', 'DESC']]
        });

        res.status(200).json(blockedUsers.map((blockedUser) => addLevelToFriendRecord(blockedUser, userId)));
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while retrieving blocked users.' });
    }
};

exports.read = async (req, res) => {
    try {
        const friendId = req.params.id;
        const friend = await Friend.findOne({
            where: { user_id: req.auth.userId, friend_id: friendId },
            include: friendDetailsInclude
        });

        if (!friend) {
            return res.status(404).json({ message: 'Ami non trouvÃ©.' });
        }

        res.status(200).json(addLevelToFriendRecord(friend, req.auth.userId));
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while retrieving the friend.' });
    }
};

exports.addFriend = async (req, res) => {
    try {
        const userId = req.auth.userId;
        const friendUsername = req.params.username;

        const friend = await User.findOne({ where: { username: friendUsername } });

        if (!friend) {
            return res.status(404).json({ message: 'Utilisateur introuvable' });
        }

        const friendId = friend.id;

        if (userId === friendId) {
            return res.status(400).json({ message: 'Vous ne pouvez pas vous ajouter comme ami' });
        }

        const [existingFriend, reverseFriendship] = await Promise.all([
            Friend.findOne({ where: { user_id: userId, friend_id: friendId } }),
            Friend.findOne({ where: { user_id: friendId, friend_id: userId } })
        ]);

        if (existingFriend) {
            if (existingFriend.status === FRIEND_STATUS.ACTIVE) {
                return res.status(400).json({ message: 'Cet utilisateur est dÃ©jÃ  votre ami' });
            }
            if (existingFriend.status === FRIEND_STATUS.PENDING) {
                return res.status(400).json({ message: "Demande d'ami dÃ©jÃ  envoyÃ©e, en attente d'acceptation." });
            }
            return res.status(400).json({ message: 'Cet utilisateur est bloquÃ©. DÃ©bloquez-le avant de renvoyer une demande.' });
        }

        if (reverseFriendship) {
            if (reverseFriendship.status === FRIEND_STATUS.ACTIVE) {
                return res.status(400).json({ message: 'Cet utilisateur est dÃ©jÃ  votre ami' });
            }
            if (reverseFriendship.status === FRIEND_STATUS.PENDING) {
                return res.status(400).json({ message: "Cet utilisateur vous a dÃ©jÃ  envoyÃ© une demande. Acceptez-la." });
            }
            return res.status(400).json({ message: 'Cet utilisateur vous a bloquÃ© ou la relation est bloquÃ©e.' });
        }

        const newFriend = await Friend.create({
            user_id: userId,
            friend_id: friendId,
            status: FRIEND_STATUS.PENDING
        });

        const senderUser = await User.findByPk(userId, {
            attributes: ['id', 'username', 'avatar']
        });
        const io = req.app?.locals?.io;
        if (io) {
            io.to(`user:${friendId}`).emit('friendRequestReceived', {
                requestId: newFriend.id,
                status: newFriend.status,
                createdAt: newFriend.createdAt,
                sender: {
                    id: userId,
                    username: senderUser?.username || null,
                    avatar: senderUser?.avatar || null
                }
            });

        }

        await sendPushToUsers({
            userIds: [friendId],
            data: {
                event: 'friendRequestReceived',
                requestId: newFriend.id,
                senderId: userId,
                senderUsername: senderUser?.username || ''
            },
            excludeUserId: userId
        });

        res.status(201).json(newFriend);
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while adding the friend.' });
    }
};

exports.respondToRequest = async (req, res) => {
    try {
        const requestId = parseInt(req.params.requestId, 10);
        const userId = req.auth.userId;
        const { status } = req.body;

        if (![FRIEND_STATUS.ACTIVE, FRIEND_STATUS.BLOQUED].includes(status)) {
            return res.status(400).json({ message: 'Invalid status for a friend request response.' });
        }

        const incomingRequest = await Friend.findOne({
            where: {
                id: requestId,
                friend_id: userId,
                status: FRIEND_STATUS.PENDING
            }
        });

        if (!incomingRequest) {
            return res.status(404).json({ message: 'Friend request not found.' });
        }

        incomingRequest.status = status;
        await incomingRequest.save();

        const responderUser = await User.findByPk(userId, {
            attributes: ['id', 'username', 'avatar']
        });

        if (status === FRIEND_STATUS.ACTIVE) {
            const [reverseFriendship, created] = await Friend.findOrCreate({
                where: {
                    user_id: userId,
                    friend_id: incomingRequest.user_id
                },
                defaults: { status: FRIEND_STATUS.ACTIVE }
            });

            if (!created && reverseFriendship.status !== FRIEND_STATUS.ACTIVE) {
                reverseFriendship.status = FRIEND_STATUS.ACTIVE;
                await reverseFriendship.save();
            }
        }

        const io = req.app?.locals?.io;
        if (io) {
            io.to(`user:${incomingRequest.user_id}`).emit('friendRequestResponded', {
                requestId: incomingRequest.id,
                status: incomingRequest.status,
                respondedAt: incomingRequest.updatedAt,
                responder: {
                    id: responderUser?.id || userId,
                    username: responderUser?.username || null,
                    avatar: responderUser?.avatar || null
                }
            });
        }

        return res.status(200).json(incomingRequest);
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while responding to the friend request.' });
    }
};

exports.cancelOutgoingRequest = async (req, res) => {
    try {
        const requestId = parseInt(req.params.requestId, 10);
        const userId = req.auth.userId;

        const outgoingRequest = await Friend.findOne({
            where: {
                id: requestId,
                user_id: userId,
                status: FRIEND_STATUS.PENDING
            }
        });

        if (!outgoingRequest) {
            return res.status(404).json({ message: 'Outgoing friend request not found.' });
        }

        const receiverId = outgoingRequest.friend_id;
        await outgoingRequest.destroy();

        const io = req.app?.locals?.io;
        if (io) {
            io.to(`user:${receiverId}`).emit('friendRequestCancelled', {
                requestId,
                cancelledBy: userId
            });
        }

        return res.status(204).send();
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while cancelling the friend request.' });
    }
};

exports.blockUser = async (req, res) => {
    try {
        const userId = req.auth.userId;
        const targetUserId = parseInt(req.params.id, 10);

        if (!Number.isInteger(targetUserId)) {
            return res.status(400).json({ message: 'Invalid user id.' });
        }

        if (userId === targetUserId) {
            return res.status(400).json({ message: 'Vous ne pouvez pas vous bloquer vous-même.' });
        }

        const targetUser = await User.findByPk(targetUserId);
        if (!targetUser) {
            return res.status(404).json({ message: 'Utilisateur introuvable.' });
        }

        const [friendship] = await Friend.findOrCreate({
            where: { user_id: userId, friend_id: targetUserId },
            defaults: { status: FRIEND_STATUS.BLOQUED }
        });

        if (friendship.status !== FRIEND_STATUS.BLOQUED) {
            friendship.status = FRIEND_STATUS.BLOQUED;
            await friendship.save();
        }

        await Friend.destroy({
            where: {
                user_id: targetUserId,
                friend_id: userId,
                status: FRIEND_STATUS.PENDING
            }
        });

        const io = req.app?.locals?.io;
        if (io) {
            io.to(`user:${targetUserId}`).emit('friendshipBlocked', {
                blockedBy: userId,
                blockedUserId: targetUserId
            });
        }

        return res.status(200).json(friendship);
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while blocking this user.' });
    }
};

exports.unblockUser = async (req, res) => {
    try {
        const userId = req.auth.userId;
        const targetUserId = parseInt(req.params.id, 10);

        if (!Number.isInteger(targetUserId)) {
            return res.status(400).json({ message: 'Invalid user id.' });
        }

        const blockedFriendship = await Friend.findOne({
            where: {
                user_id: userId,
                friend_id: targetUserId,
                status: FRIEND_STATUS.BLOQUED
            }
        });

        if (!blockedFriendship) {
            return res.status(404).json({ message: 'Blocked user not found.' });
        }

        await blockedFriendship.destroy();

        const io = req.app?.locals?.io;
        if (io) {
            io.to(`user:${targetUserId}`).emit('friendshipUnblocked', {
                unblockedBy: userId,
                unblockedUserId: targetUserId
            });
        }

        return res.status(204).send();
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while unblocking this user.' });
    }
};

// Backward compatibility route: PUT /friends/:id where :id = other user id
exports.update = async (req, res) => {
    try {
        const friendId = parseInt(req.params.id, 10);
        const userId = req.auth.userId;
        const { status } = req.body;

        if (![FRIEND_STATUS.ACTIVE, FRIEND_STATUS.PENDING, FRIEND_STATUS.BLOQUED].includes(status)) {
            return res.status(400).json({ message: 'Invalid status.' });
        }

        const ownFriendship = await Friend.findOne({
            where: { user_id: userId, friend_id: friendId }
        });

        if (ownFriendship) {
            ownFriendship.status = status;
            await ownFriendship.save();
            return res.status(200).json(ownFriendship);
        }

        const incomingRequest = await Friend.findOne({
            where: {
                user_id: friendId,
                friend_id: userId,
                status: FRIEND_STATUS.PENDING
            }
        });

        if (!incomingRequest) {
            return res.status(404).json({ message: 'Friendship not found.' });
        }

        incomingRequest.status = status;
        await incomingRequest.save();

        if (status === FRIEND_STATUS.ACTIVE) {
            const [reverseFriendship, created] = await Friend.findOrCreate({
                where: { user_id: userId, friend_id: friendId },
                defaults: { status: FRIEND_STATUS.ACTIVE }
            });

            if (!created && reverseFriendship.status !== FRIEND_STATUS.ACTIVE) {
                reverseFriendship.status = FRIEND_STATUS.ACTIVE;
                await reverseFriendship.save();
            }
        }

        return res.status(200).json(incomingRequest);
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while updating the friend status.' });
    }
};

exports.delete = async (req, res) => {
    try {
        const friendId = parseInt(req.params.id, 10);
        const userId = req.auth.userId;

        const deletedCount = await Friend.destroy({
            where: {
                [Op.or]: [
                    { user_id: userId, friend_id: friendId },
                    { user_id: friendId, friend_id: userId }
                ]
            }
        });

        if (!deletedCount) {
            return res.status(404).json({ message: 'Friendship not found.' });
        }

        const io = req.app?.locals?.io;
        if (io) {
            io.to(`user:${userId}`).emit('friendshipDeleted', {
                deletedBy: userId,
                otherUserId: friendId
            });
            io.to(`user:${friendId}`).emit('friendshipDeleted', {
                deletedBy: userId,
                otherUserId: userId
            });
        }

        return res.status(204).send();
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while deleting the friendship.' });
    }
};
