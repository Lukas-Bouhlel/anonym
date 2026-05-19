const { PrivateMessage, Channel, UserChannel, User, Inventory, Shop, Friend } = require('../models');
const { Op } = require('sequelize');
const { deleteUploadFileIfExists } = require('../utils/fileCleanup');
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
            imageUrl = `${req.protocol}://${req.get('host')}/uploads/messages/images/${req.file.filename}`;
        }

        // Créer le message
        const message = await PrivateMessage.create({
            sender_id: userId,
            content: content || null,
            image_url: imageUrl,
            channel_id: channelId,
            status: 'unread',
            createdAt: new Date()
        });

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
        const io = req.app.locals.io;
        if (io) {
            io.to(channelId.toString()).emit('newMessage', {
                id: message.message_id,
                content: message.content,
                imageUrl: message.image_url,
                sender,
                createdAt: message.createdAt
            });

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

        return res.status(201).json({
            id: message.message_id,
            content: message.content,
            imageUrl: message.image_url,
            sender,
            createdAt: message.createdAt
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

        const imageUrl = `${req.protocol}://${req.get('host')}/uploads/messages/images/${req.file.filename}`;
        
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
        await message.destroy();

        res.status(200).json({ message: "Message deleted successfully." });
    } catch (error) {
        res.status(500).json({ message: error.message || 'Une erreur est survenue lors de la suppression du message.' });
    }
};
