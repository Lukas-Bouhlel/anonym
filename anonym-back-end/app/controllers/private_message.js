const { PrivateMessage, Channel, UserChannel, User, Inventory, Shop, Friend, UserPointDaily, sequelize } = require('../models');
const { Op } = require('sequelize');
const { deleteUploadFileIfExists } = require('../utils/fileCleanup');
const { sendPushToUsers } = require('../utils/pushNotifications');
let hasAllowNonFriendDmsColumnCache = null;

const resolveIo = (req) => {
    return req?.app?.locals?.io || req?.app?.get?.('io') || null;
};

const updateChannelReputationScore = async (channelId) => {
    const channel = await Channel.findByPk(channelId);
    if (!channel) return null;

    // Reputation only applies to public groups (exclude private DMs).
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

/**
 * @module privateMessageController
 * @description Ce module contient des fonctions pour gérer les messages privés, y compris la mise à jour et la suppression des messages.
 */

/**
 * Envoyer un message avec une image optionnelle dans un channel en un seul appel.
 *
 * @async
 * @function sendMessageWithImage
 * @param {Object} req - L'objet de requête.
 * @param {Object} req.params.channelId - L'ID du channel.
 * @param {Object} req.body - Le corps de la requête.
 * @param {string} req.body.content - Le contenu du message.
 * @param {Object} req.file - Le fichier image uploadé (optionnel).
 * @param {Object} req.auth - Les données d'authentification.
 * @param {number} req.auth.userId - L'ID de l'utilisateur authentifié.
 * @param {Object} res - L'objet de réponse.
 * @returns {Object} 201 - Le message créé avec les détails du sender.
 * @returns {Object} 400 - Erreur de validation.
 * @returns {Object} 403 - Accès refusé (pas membre du channel).
 * @returns {Object} 404 - Channel ou channel type invalide.
 * @returns {Object} 500 - Erreur interne du serveur.
 */
exports.sendMessageWithImage = async (req, res) => {
    try {
        const { channelId } = req.params;
        const { content } = req.body;
        const userId = req.auth.userId;

        // Valider que le contenu ou l'image existe
        if (!content && !req.file) {
            return res.status(400).json({ message: 'Le contenu ou une image est requis.' });
        }

        // Vérifier que le channel existe
        const channel = await Channel.findByPk(channelId);
        if (!channel) {
            return res.status(404).json({ message: 'Channel non trouvé.' });
        }

        // Vérifier que l'utilisateur est membre du channel
        if (channel.channel_type === 'PRIVATE_DM') {
            const members = await UserChannel.findAll({
                where: { channel_id: channelId },
                attributes: ['user_id'],
                raw: true
            });

            const recipient = members.find((member) => member.user_id !== userId);
            if (!recipient) {
                return res.status(400).json({ message: 'Discussion privee invalide.' });
            }

            const blockedRelationshipExists = await hasBlockedRelationship(userId, recipient.user_id);
            if (blockedRelationshipExists) {
                return res.status(403).json({
                    message: 'Impossible d envoyer un message: cette relation est bloquee.'
                });
            }

            const allowNonFriendDmsColumnExists = await hasAllowNonFriendDmsColumn();
            if (allowNonFriendDmsColumnExists) {
                const recipientUser = await User.findByPk(recipient.user_id, {
                    attributes: ['id', 'allow_non_friend_dms']
                });

                if (!recipientUser) {
                    return res.status(404).json({ message: 'Destinataire introuvable.' });
                }

                if (!recipientUser.allow_non_friend_dms) {
                    const activeFriendship = await Friend.findOne({
                        where: {
                            status: 'ACTIVE',
                            [Op.or]: [
                                { user_id: userId, friend_id: recipient.user_id },
                                { user_id: recipient.user_id, friend_id: userId }
                            ]
                        }
                    });

                    if (!activeFriendship) {
                        return res.status(403).json({
                            message: 'Cet utilisateur refuse les messages prives des non-amis.'
                        });
                    }
                }
            }
        }

        const isMember = await UserChannel.findOne({
            where: { channel_id: channelId, user_id: userId }
        });
        if (!isMember) {
            return res.status(403).json({ message: 'Vous ne faites pas partie de ce channel.' });
        }

        // Construire l'URL de l'image si elle existe
        let imageUrl = null;
        if (req.file) {
            imageUrl = `/uploads/messages/images/${req.file.filename}`;
        }

        let awardedPoints = 1;
        let appliedMultiplier = 1;
        let updatedTotalPoints = 0;

        const message = await sequelize.transaction(async (transaction) => {
            const activeItems = await Inventory.findAll({
                where: { user_id: userId, active: true },
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
                sender_id: userId,
                content: content || null,
                image_url: imageUrl,
                channel_id: channelId,
                status: 'unread',
                createdAt: new Date()
            }, { transaction });

            const user = await User.findByPk(userId, { transaction, lock: transaction.LOCK.UPDATE });
            const nextTotalPoints = (user.total_points || 0) + awardedPoints;
            updatedTotalPoints = nextTotalPoints;
            user.total_points = nextTotalPoints;
            await user.save({ transaction });

            const currentDate = new Date().toISOString().slice(0, 10);
            const [dailyStat] = await UserPointDaily.findOrCreate({
                where: {
                    user_id: userId,
                    stat_date: currentDate
                },
                defaults: {
                    user_id: userId,
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

        await updateChannelReputationScore(channelId);

        // Récupérer les détails du sender
        const sender = await User.findByPk(userId, {
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

        // Émettre l'événement Socket.io en temps réel
        const channelMembers = await UserChannel.findAll({
            where: { channel_id: channelId },
            attributes: ['user_id'],
            raw: true
        });

        const io = resolveIo(req);
        if (io) {
            const messagePayload = {
                id: message.message_id,
                content: message.content,
                imageUrl: message.image_url,
                channelId: Number(channelId),
                senderId: userId,
                status: message.status,
                sender,
                createdAt: message.createdAt
            };

            const emittedRooms = new Set();
            const emitToRoom = (room) => {
                if (!room || emittedRooms.has(room)) return;
                emittedRooms.add(room);
                io.to(room).emit('newMessage', messagePayload);
            };

            emitToRoom(channelId.toString());
            for (const member of channelMembers) {
                emitToRoom(`user:${member.user_id}`);
            }

            // Mettre à jour le compte des messages non lus
            const unreadCount = await PrivateMessage.count({
                where: {
                    channel_id: channelId,
                    status: 'unread',
                    sender_id: {
                        [Op.ne]: userId
                    }
                }
            });
            io.to(channelId.toString()).emit('unreadCount', { count: unreadCount });
        }

        await sendPushToUsers({
            userIds: channelMembers.map((member) => member.user_id),
            excludeUserId: userId,
            data: {
                event: 'newMessage',
                id: message.message_id,
                channelId,
                senderId: userId,
                senderUsername: sender?.username || ''
            }
        });

        return res.status(201).json({
            id: message.message_id,
            content: message.content,
            imageUrl: message.image_url,
            channelId: Number(channelId),
            senderId: userId,
            status: message.status,
            sender,
            createdAt: message.createdAt,
            points: {
                awarded: awardedPoints,
                multiplier: Number(appliedMultiplier.toFixed(2)),
                total: updatedTotalPoints
            }
        });
    } catch (error) {
        console.error('Error sending message:', error);
        return res.status(500).json({ message: error.message || 'Une erreur est survenue lors de l\'envoi du message.' });
    }
};

/**
 * Upload une image pour un message.
 *
 * @async
 * @function uploadImage
 * @param {Object} req - L'objet de requête.
 * @param {Object} res - L'objet de réponse.
 * @returns {Object} 200 - L'URL de l'image.
 * @returns {Object} 400 - Erreur si aucune image n'est fournie.
 * @returns {Object} 500 - Erreur interne du serveur.
 */
exports.uploadImage = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ message: 'Aucune image fournie.' });
        }

        const imageUrl = `/uploads/messages/images/${req.file.filename}`;
        
        res.status(200).json({ imageUrl });
    } catch (error) {
        res.status(500).json({ message: error.message || 'Une erreur est survenue lors de l\'upload de l\'image.' });
    }
};

/**
 * Mettre à jour un message.
 *
 * @async
 * @function update
 * @param {Object} req - L'objet de requête.
 * @param {Object} res - L'objet de réponse.
 * @throws {Object} 404 - Non trouvé si le message n'existe pas ou si l'utilisateur n'est pas l'expéditeur.
 * @returns {Object} 200 - Le message mis à jour.
 * @returns {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la mise à jour du message.
 */
exports.update = async (req, res) => {
    try {
        const { message_id } = req.params;
        const { content } = req.body;

        const message = await PrivateMessage.findOne({ where: { message_id, sender_id: req.auth.userId } });

        if (!message) {
            return res.status(404).json({ message: "Message not found or you're not the sender." });
        }

        message.content = content;
        await message.save();

        const sender = await User.findByPk(req.auth.userId, {
            attributes: ['id', 'username', 'avatar']
        });
        const payload = {
            id: message.message_id,
            content: message.content,
            imageUrl: message.image_url,
            channelId: Number(message.channel_id),
            senderId: req.auth.userId,
            status: message.status,
            sender,
            createdAt: message.createdAt,
            updatedAt: message.updatedAt
        };
        const channel = await Channel.findByPk(message.channel_id);
        const io = resolveIo(req);
        if (io) {
            if (channel?.channel_type === 'PRIVATE_DM') {
                const channelMembers = await UserChannel.findAll({
                    where: { channel_id: message.channel_id },
                    attributes: ['user_id'],
                    raw: true
                });
                for (const member of channelMembers) {
                    io.to(`user:${member.user_id}`).emit('messageUpdated', payload);
                }
            } else {
                io.to(message.channel_id.toString()).emit('messageUpdated', payload);
            }
        }

        res.status(200).json(message);
    } catch (error) {
        res.status(500).json({ message: error.message || 'Une erreur est survenue lors de la mise à jour du message.' });
    }
};

/**
 * Supprimer un message.
 *
 * @async
 * @function delete
 * @param {Object} req - L'objet de requête.
 * @param {Object} res - L'objet de réponse.
 * @throws {Object} 404 - Non trouvé si le message n'existe pas ou si l'utilisateur n'est pas l'expéditeur.
 * @returns {Object} 200 - Un message de confirmation que le message a été supprimé avec succès.
 * @returns {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la suppression du message.
 */
exports.delete = async (req, res) => {
    try {
        const { message_id } = req.params;

        const message = await PrivateMessage.findOne({ where: { message_id, sender_id: req.auth.userId } });

        if (!message) {
            return res.status(404).json({ message: "Message not found or you're not the sender." });
        }

        deleteUploadFileIfExists(message.image_url);
        const channelId = message.channel_id;
        await message.destroy();
        await updateChannelReputationScore(channelId);

        const channel = await Channel.findByPk(channelId);
        const payload = {
            messageId: Number(message_id),
            message_id: Number(message_id),
            channelId: Number(channelId),
            channel_id: Number(channelId)
        };
        const io = resolveIo(req);
        if (io) {
            if (channel?.channel_type === 'PRIVATE_DM') {
                const channelMembers = await UserChannel.findAll({
                    where: { channel_id: channelId },
                    attributes: ['user_id'],
                    raw: true
                });
                for (const member of channelMembers) {
                    io.to(`user:${member.user_id}`).emit('messageDeleted', payload);
                }
            } else {
                io.to(channelId.toString()).emit('messageDeleted', payload);
            }
        }

        res.status(200).json({ message: "Message deleted successfully." });
    } catch (error) {
        res.status(500).json({ message: error.message || 'Une erreur est survenue lors de la suppression du message.' });
    }
};
