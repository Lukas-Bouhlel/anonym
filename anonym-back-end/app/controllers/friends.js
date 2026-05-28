const { Op } = require('sequelize');
const { Friend, User, Inventory, Shop } = require('../models');
const { getLevelFromPoints } = require('../utils/points');
const { sendPushToUsers } = require('../utils/pushNotifications');

const FRIEND_STATUS = {
    ACTIVE: 'ACTIVE',
    PENDING: 'PENDING',
    BLOQUED: 'BLOQUED'
};

const FRIEND_REQUEST_RESPONSE = {
    ACCEPTED: FRIEND_STATUS.ACTIVE,
    DECLINED: 'DECLINED',
    LEGACY_BLOCKED: FRIEND_STATUS.BLOQUED
};
const NON_BLOCKED_STATUSES = [FRIEND_STATUS.ACTIVE, FRIEND_STATUS.PENDING];

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

const emitFriendsStateUpdated = (io, userIds, reason, extra = {}) => {
    if (!io) return;
    const uniqueUserIds = [...new Set(
        userIds
            .map((value) => parseInt(value, 10))
            .filter((value) => Number.isInteger(value) && value > 0)
    )];

    if (uniqueUserIds.length === 0) return;

    const payload = {
        reason,
        updatedAt: new Date().toISOString(),
        ...extra
    };
    console.log(`[FRIENDS-RT] emit friendsStateUpdated reason=${reason} users=${uniqueUserIds.join(',')} payload=${JSON.stringify(payload)}`);

    for (const userId of uniqueUserIds) {
        io.to(`user:${userId}`).emit('friendsStateUpdated', payload);
    }
};

const resolveIo = (req) => {
    return req?.app?.locals?.io || req?.app?.get?.('io') || null;
};

const applyBlockRelationship = async ({ blockerId, blockedId, transaction }) => {
    const [friendship] = await Friend.findOrCreate({
        where: { user_id: blockerId, friend_id: blockedId },
        defaults: { status: FRIEND_STATUS.BLOQUED },
        transaction
    });

    if (friendship.status !== FRIEND_STATUS.BLOQUED) {
        friendship.status = FRIEND_STATUS.BLOQUED;
        await friendship.save({ transaction });
    }

    await Friend.destroy({
        where: {
            user_id: blockerId,
            friend_id: blockedId,
            id: { [Op.ne]: friendship.id }
        },
        transaction
    });

    await Friend.destroy({
        where: {
            user_id: blockedId,
            friend_id: blockerId,
            status: { [Op.in]: NON_BLOCKED_STATUSES }
        },
        transaction
    });

    return friendship;
};

exports.readAll = async (req, res) => {
    try {
        const userId = req.auth.userId;
        const [friends, blockedRelations] = await Promise.all([
            Friend.findAll({
                where: { user_id: userId, status: FRIEND_STATUS.ACTIVE },
                include: [friendDetailsInclude]
            }),
            Friend.findAll({
                attributes: ['user_id', 'friend_id'],
                where: {
                    status: FRIEND_STATUS.BLOQUED,
                    [Op.or]: [
                        { user_id: userId },
                        { friend_id: userId }
                    ]
                },
                raw: true
            })
        ]);

        const blockedUserIds = new Set(
            blockedRelations.map((relation) => {
                const relationUserId = parseInt(relation.user_id, 10);
                const relationFriendId = parseInt(relation.friend_id, 10);
                return relationUserId === userId
                    ? relationFriendId
                    : relationUserId;
            })
        );

        const visibleFriends = friends.filter((friend) => !blockedUserIds.has(parseInt(friend.friend_id, 10)));
        res.status(200).json(visibleFriends.map((friend) => addLevelToFriendRecord(friend, userId)));
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while retrieving friends.' });
    }
};

exports.readIncomingRequests = async (req, res) => {
    try {
        const userId = req.auth.userId;
        const [incomingRequests, blockedRelations] = await Promise.all([
            Friend.findAll({
                where: { friend_id: userId, status: FRIEND_STATUS.PENDING },
                include: [{
                    model: User,
                    as: 'User',
                    attributes: ['id', 'username', 'email', 'avatar', 'total_points', 'presence_status']
                }],
                order: [['createdAt', 'DESC']]
            }),
            Friend.findAll({
                attributes: ['user_id', 'friend_id'],
                where: {
                    status: FRIEND_STATUS.BLOQUED,
                    [Op.or]: [
                        { user_id: userId },
                        { friend_id: userId }
                    ]
                },
                raw: true
            })
        ]);

        const blockedUserIds = new Set(
            blockedRelations.map((relation) => {
                const relationUserId = parseInt(relation.user_id, 10);
                const relationFriendId = parseInt(relation.friend_id, 10);
                return relationUserId === userId
                    ? relationFriendId
                    : relationUserId;
            })
        );

        const filteredRequests = incomingRequests.filter((request) => !blockedUserIds.has(parseInt(request.user_id, 10)));
        res.status(200).json(filteredRequests.map((request) => addLevelToFriendRecord(request, userId)));
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
            return res.status(404).json({ message: 'Ami non trouvé.' });
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
        console.log(`[FRIENDS] addFriend requester=${userId} username=${friendUsername}`);

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
                return res.status(400).json({ message: 'Cet utilisateur est déjà votre ami' });
            }
            if (existingFriend.status === FRIEND_STATUS.PENDING) {
                return res.status(400).json({ message: "Demande d'ami déjà envoyée, en attente d'acceptation." });
            }
            return res.status(400).json({ message: 'Cet utilisateur est bloqué. Débloquez-le avant de renvoyer une demande.' });
        }

        if (reverseFriendship) {
            if (reverseFriendship.status === FRIEND_STATUS.ACTIVE) {
                return res.status(400).json({ message: 'Cet utilisateur est déjà votre ami' });
            }
            if (reverseFriendship.status === FRIEND_STATUS.PENDING) {
                return res.status(400).json({ message: "Cet utilisateur vous a déjà envoyé une demande. Acceptez-la." });
            }
            return res.status(400).json({ message: 'Cet utilisateur vous a bloqué ou la relation est bloquée.' });
        }

        const newFriend = await Friend.create({
            user_id: userId,
            friend_id: friendId,
            status: FRIEND_STATUS.PENDING
        });

        const senderUser = await User.findByPk(userId, {
            attributes: ['id', 'username', 'avatar']
        });
        const io = resolveIo(req);
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
            io.to(`user:${userId}`).emit('friendRequestSent', {
                requestId: newFriend.id,
                status: newFriend.status,
                createdAt: newFriend.createdAt,
                receiver: {
                    id: friendId,
                    username: friend.username || null,
                    avatar: friend.avatar || null
                }
            });

            emitFriendsStateUpdated(io, [userId, friendId], 'friend_request_created', {
                requestId: newFriend.id,
                senderId: userId,
                receiverId: friendId
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
        const rawStatusInput = (
            req.body?.status ??
            req.body?.friendStatus ??
            req.body?.state ??
            ''
        ).toString().trim().toUpperCase();
        const rawStatus = (
            rawStatusInput === FRIEND_STATUS.ACTIVE ||
            rawStatusInput === 'ACCEPTED' ||
            rawStatusInput === 'ACCEPT' ||
            rawStatusInput === 'APPROVED'
        )
            ? FRIEND_REQUEST_RESPONSE.ACCEPTED
            : rawStatusInput;
        console.log(`[FRIENDS] respondToRequest user=${userId} requestId=${requestId} status=${rawStatus}`);

        if (![FRIEND_REQUEST_RESPONSE.ACCEPTED, FRIEND_REQUEST_RESPONSE.DECLINED, FRIEND_REQUEST_RESPONSE.LEGACY_BLOCKED].includes(rawStatus)) {
            console.warn(
                `[FRIENDS] respondToRequest invalid status user=${userId} requestId=${requestId} raw=${rawStatusInput} body=${JSON.stringify(req.body || {})}`,
            );
            return res.status(400).json({
                message: `Invalid status for a friend request response. Received: ${rawStatusInput || 'EMPTY'}.`
            });
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

        const responderUser = await User.findByPk(userId, {
            attributes: ['id', 'username', 'avatar']
        });

        if (rawStatus === FRIEND_REQUEST_RESPONSE.ACCEPTED) {
            incomingRequest.status = FRIEND_STATUS.ACTIVE;
            await incomingRequest.save();

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
        } else {
            await incomingRequest.destroy();
        }

        const io = resolveIo(req);
        if (io) {
            const responsePayload = {
                requestId: incomingRequest.id,
                status: rawStatus === FRIEND_REQUEST_RESPONSE.ACCEPTED ? FRIEND_STATUS.ACTIVE : FRIEND_REQUEST_RESPONSE.DECLINED,
                respondedAt: new Date().toISOString(),
                responder: {
                    id: responderUser?.id || userId,
                    username: responderUser?.username || null,
                    avatar: responderUser?.avatar || null
                }
            };
            io.to(`user:${incomingRequest.user_id}`).emit('friendRequestResponded', responsePayload);
            io.to(`user:${userId}`).emit('friendRequestResponded', responsePayload);
            emitFriendsStateUpdated(
                io,
                [incomingRequest.user_id, userId],
                rawStatus === FRIEND_REQUEST_RESPONSE.ACCEPTED
                    ? 'friend_request_accepted'
                    : 'friend_request_declined',
                {
                    requestId: incomingRequest.id
                }
            );
        }

        if (rawStatus === FRIEND_REQUEST_RESPONSE.ACCEPTED) {
            return res.status(200).json(incomingRequest);
        }
        return res.status(204).send();
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while responding to the friend request.' });
    }
};

exports.cancelOutgoingRequest = async (req, res) => {
    try {
        const requestId = parseInt(req.params.requestId, 10);
        const userId = req.auth.userId;
        console.log(`[FRIENDS] cancelOutgoingRequest user=${userId} requestId=${requestId}`);

        const outgoingRequest = await Friend.findOne({
            where: {
                id: requestId,
                user_id: userId,
                status: FRIEND_STATUS.PENDING
            }
        });

        if (!outgoingRequest) {
            const alreadyHandledRequest = await Friend.findOne({
                where: {
                    id: requestId,
                    user_id: userId
                }
            });

            // Keep cancellation idempotent for real-time race conditions.
            if (!alreadyHandledRequest) {
                return res.status(204).send();
            }

            if (alreadyHandledRequest.status === FRIEND_STATUS.PENDING) {
                await alreadyHandledRequest.destroy();
            }
            return res.status(204).send();
        }

        const receiverId = outgoingRequest.friend_id;
        await outgoingRequest.destroy();

        const io = resolveIo(req);
        if (io) {
            const payload = {
                requestId,
                cancelledBy: userId
            };
            io.to(`user:${receiverId}`).emit('friendRequestCancelled', payload);
            io.to(`user:${userId}`).emit('friendRequestCancelled', payload);
            emitFriendsStateUpdated(io, [userId, receiverId], 'friend_request_cancelled', {
                requestId
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
        console.log(`[FRIENDS] blockUser user=${userId} target=${targetUserId}`);

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

        const friendship = await Friend.sequelize.transaction(async (transaction) => {
            return applyBlockRelationship({
                blockerId: userId,
                blockedId: targetUserId,
                transaction
            });
        });

        const io = resolveIo(req);
        if (io) {
            const payload = {
                blockedBy: userId,
                blockedUserId: targetUserId
            };
            io.to(`user:${targetUserId}`).emit('friendshipBlocked', payload);
            io.to(`user:${userId}`).emit('friendshipBlocked', payload);
            emitFriendsStateUpdated(io, [userId, targetUserId], 'friend_blocked', {
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
        console.log(`[FRIENDS] unblockUser user=${userId} target=${targetUserId}`);

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

        const io = resolveIo(req);
        if (io) {
            const payload = {
                unblockedBy: userId,
                unblockedUserId: targetUserId
            };
            io.to(`user:${targetUserId}`).emit('friendshipUnblocked', payload);
            io.to(`user:${userId}`).emit('friendshipUnblocked', payload);
            emitFriendsStateUpdated(io, [userId, targetUserId], 'friend_unblocked', {
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
        const status = (req.body?.status || '').toString().trim().toUpperCase();
        console.log(`[FRIENDS] legacyUpdate user=${userId} other=${friendId} status=${status}`);

        if (![FRIEND_STATUS.ACTIVE, FRIEND_STATUS.PENDING, FRIEND_STATUS.BLOQUED, FRIEND_REQUEST_RESPONSE.DECLINED].includes(status)) {
            return res.status(400).json({ message: 'Invalid status.' });
        }

        const ownFriendship = await Friend.findOne({
            where: { user_id: userId, friend_id: friendId }
        });
        const io = resolveIo(req);

        if (ownFriendship) {
            if (status === FRIEND_REQUEST_RESPONSE.DECLINED) {
                await ownFriendship.destroy();
                if (io) {
                    io.to(`user:${friendId}`).emit('friendRequestCancelled', {
                        requestId: ownFriendship.id,
                        cancelledBy: userId
                    });
                    io.to(`user:${userId}`).emit('friendRequestCancelled', {
                        requestId: ownFriendship.id,
                        cancelledBy: userId
                    });
                    emitFriendsStateUpdated(io, [userId, friendId], 'friend_request_cancelled', {
                        requestId: ownFriendship.id
                    });
                }
                return res.status(204).send();
            }
            const updatedFriendship = status === FRIEND_STATUS.BLOQUED
                ? await Friend.sequelize.transaction(async (transaction) => {
                    return applyBlockRelationship({
                        blockerId: userId,
                        blockedId: friendId,
                        transaction
                    });
                })
                : ownFriendship;

            if (status !== FRIEND_STATUS.BLOQUED) {
                ownFriendship.status = status;
                await ownFriendship.save();
            }

            if (io) {
                if (status === FRIEND_STATUS.BLOQUED) {
                    io.to(`user:${friendId}`).emit('friendshipBlocked', {
                        blockedBy: userId,
                        blockedUserId: friendId
                    });
                    io.to(`user:${userId}`).emit('friendshipBlocked', {
                        blockedBy: userId,
                        blockedUserId: friendId
                    });
                    emitFriendsStateUpdated(io, [userId, friendId], 'friend_blocked', {
                        blockedUserId: friendId
                    });
                } else if (status === FRIEND_STATUS.ACTIVE) {
                    io.to(`user:${friendId}`).emit('friendRequestResponded', {
                        requestId: ownFriendship.id,
                        status: FRIEND_STATUS.ACTIVE,
                        respondedAt: new Date().toISOString(),
                        responder: {
                            id: userId
                        }
                    });
                    io.to(`user:${userId}`).emit('friendRequestResponded', {
                        requestId: ownFriendship.id,
                        status: FRIEND_STATUS.ACTIVE,
                        respondedAt: new Date().toISOString(),
                        responder: {
                            id: userId
                        }
                    });
                    emitFriendsStateUpdated(io, [userId, friendId], 'friend_request_accepted', {
                        requestId: ownFriendship.id
                    });
                }
            }
            return res.status(200).json(updatedFriendship);
        }

        const incomingRequest = await Friend.findOne({
            where: {
                user_id: friendId,
                friend_id: userId,
                status: FRIEND_STATUS.PENDING
            }
        });

        if (!incomingRequest) {
            if (status === FRIEND_STATUS.BLOQUED) {
                const targetUser = await User.findByPk(friendId);
                if (!targetUser) {
                    return res.status(404).json({ message: 'Utilisateur introuvable.' });
                }

                const blockedFriendship = await Friend.sequelize.transaction(async (transaction) => {
                    return applyBlockRelationship({
                        blockerId: userId,
                        blockedId: friendId,
                        transaction
                    });
                });

                if (io) {
                    io.to(`user:${friendId}`).emit('friendshipBlocked', {
                        blockedBy: userId,
                        blockedUserId: friendId
                    });
                    io.to(`user:${userId}`).emit('friendshipBlocked', {
                        blockedBy: userId,
                        blockedUserId: friendId
                    });
                    emitFriendsStateUpdated(io, [userId, friendId], 'friend_blocked', {
                        blockedUserId: friendId
                    });
                }
                return res.status(200).json(blockedFriendship);
            }
            return res.status(404).json({ message: 'Friendship not found.' });
        }

        if (status === FRIEND_STATUS.BLOQUED) {
            const blockedFriendship = await Friend.sequelize.transaction(async (transaction) => {
                return applyBlockRelationship({
                    blockerId: userId,
                    blockedId: friendId,
                    transaction
                });
            });

            if (io) {
                io.to(`user:${friendId}`).emit('friendshipBlocked', {
                    blockedBy: userId,
                    blockedUserId: friendId
                });
                io.to(`user:${userId}`).emit('friendshipBlocked', {
                    blockedBy: userId,
                    blockedUserId: friendId
                });
                emitFriendsStateUpdated(io, [userId, friendId], 'friend_blocked', {
                    blockedUserId: friendId
                });
            }
            return res.status(200).json(blockedFriendship);
        }

        if (status === FRIEND_STATUS.ACTIVE) {
            incomingRequest.status = status;
            await incomingRequest.save();
            const [reverseFriendship, created] = await Friend.findOrCreate({
                where: { user_id: userId, friend_id: friendId },
                defaults: { status: FRIEND_STATUS.ACTIVE }
            });

            if (!created && reverseFriendship.status !== FRIEND_STATUS.ACTIVE) {
                reverseFriendship.status = FRIEND_STATUS.ACTIVE;
                await reverseFriendship.save();
            }

            if (io) {
                const payload = {
                    requestId: incomingRequest.id,
                    status: FRIEND_STATUS.ACTIVE,
                    respondedAt: new Date().toISOString(),
                    responder: {
                        id: userId
                    }
                };
                io.to(`user:${friendId}`).emit('friendRequestResponded', payload);
                io.to(`user:${userId}`).emit('friendRequestResponded', payload);
                emitFriendsStateUpdated(io, [userId, friendId], 'friend_request_accepted', {
                    requestId: incomingRequest.id
                });
            }
            return res.status(200).json(incomingRequest);
        }

        await incomingRequest.destroy();
        if (io) {
            io.to(`user:${friendId}`).emit('friendRequestResponded', {
                requestId: incomingRequest.id,
                status: FRIEND_REQUEST_RESPONSE.DECLINED,
                respondedAt: new Date().toISOString(),
                responder: {
                    id: userId
                }
            });
            io.to(`user:${userId}`).emit('friendRequestResponded', {
                requestId: incomingRequest.id,
                status: FRIEND_REQUEST_RESPONSE.DECLINED,
                respondedAt: new Date().toISOString(),
                responder: {
                    id: userId
                }
            });
            emitFriendsStateUpdated(io, [userId, friendId], 'friend_request_declined', {
                requestId: incomingRequest.id
            });
        }
        return res.status(204).send();
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while updating the friend status.' });
    }
};

exports.delete = async (req, res) => {
    try {
        const friendId = parseInt(req.params.id, 10);
        const userId = req.auth.userId;
        console.log(`[FRIENDS] deleteFriend user=${userId} other=${friendId}`);

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

        const io = resolveIo(req);
        if (io) {
            io.to(`user:${userId}`).emit('friendshipDeleted', {
                deletedBy: userId,
                otherUserId: friendId
            });
            io.to(`user:${friendId}`).emit('friendshipDeleted', {
                deletedBy: userId,
                otherUserId: userId
            });
            emitFriendsStateUpdated(io, [userId, friendId], 'friend_deleted', {
                deletedBy: userId
            });
        }

        return res.status(204).send();
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while deleting the friendship.' });
    }
};
