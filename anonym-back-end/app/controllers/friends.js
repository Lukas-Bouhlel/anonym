const { Op } = require('sequelize');
const { Friend, User, Inventory, Shop } = require('../models');

const FRIEND_STATUS = {
    ACTIVE: 'ACTIVE',
    PENDING: 'PENDING',
    BLOQUED: 'BLOQUED'
};

const friendDetailsInclude = {
    model: User,
    as: 'FriendDetails',
    attributes: ['id', 'username', 'email', 'avatar', 'createdAt', 'updatedAt'],
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

exports.readAll = async (req, res) => {
    try {
        const userId = req.auth.userId;
        const friends = await Friend.findAll({
            where: { user_id: userId, status: FRIEND_STATUS.ACTIVE },
            include: [friendDetailsInclude]
        });

        res.status(200).json(friends);
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
                attributes: ['id', 'username', 'email', 'avatar']
            }],
            order: [['createdAt', 'DESC']]
        });

        res.status(200).json(requests);
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

        res.status(200).json(requests);
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

        res.status(200).json(blockedUsers);
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

        res.status(200).json(friend);
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

        await outgoingRequest.destroy();
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

        return res.status(204).send();
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while deleting the friendship.' });
    }
};
