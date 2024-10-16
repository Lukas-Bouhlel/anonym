const { Channel, PrivateMessage, User, UserChannel, Inventory, Shop } = require('../models');
const { Op } = require('sequelize');

/**
 * @module channelController
 * @description Ce module gère les opérations liées aux canaux, y compris la création, l'invitation d'utilisateurs, la récupération de messages, etc.
 */

/**
 * Récupérer le nombre de messages non lus dans un channel spécifique.
 *
 * @async
 * @function getUnreadMessageCount
 * @param {number} channelId - L'ID du channel à vérifier.
 * @param {number} userId - L'ID de l'utilisateur pour exclure ses messages.
 * @returns {Promise<number>} - Le nombre de messages non lus.
 */
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

/**
 * Créer un nouveau channel.
 *
 * @async
 * @function create
 * @param {Object} req - L'objet de requête contenant le nom et la description du channel.
 * @param {Object} res - L'objet de réponse.
 * @returns {Object} 201 - Détails du channel créé.
 * @throws {Object} 400 - Mauvaise requête si le nom du channel est manquant.
 * @throws {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la création du channel.
 */
exports.create = async (req, res) => {
    try {
        const { name, description } = req.body;
        const userId = req.auth.userId; 

        if(!name) {
            return res.status(400).json({ message: 'Le nom du groupe est requis' });
        }

        // Créer le channel
        const channel = await Channel.create({ 
            name, 
            description,
            created_by: userId
        });

        // Associer le channel au créateur (utilisateur actuel)
        await UserChannel.create({ user_id: userId, channel_id: channel.channel_id });

        res.status(201).json(channel);
    } catch (error) {
        res.status(500).json({ message: error.message || 'Une erreur est survenue lors de la création du channel.' });
    }
};

/**
 * Inviter un utilisateur à un channel.
 *
 * @async
 * @function invite
 * @param {Object} req - L'objet de requête contenant l'ID du channel et l'ID de l'utilisateur à inviter.
 * @param {Object} res - L'objet de réponse.
 * @returns {Object} 200 - Message de succès indiquant que l'utilisateur a été ajouté au channel.
 * @throws {Object} 400 - Mauvaise requête si l'utilisateur est déjà membre du channel.
 * @throws {Object} 500 - Erreur interne du serveur si une erreur se produit lors de l'ajout de l'utilisateur au channel.
 */
exports.invite = async (req, res) => {
    try {
        const { channelId, userId } = req.body;

        // Vérifier si l'utilisateur est déjà membre du channel
        const existingUserChannel = await UserChannel.findOne({
            where: { user_id: userId, channel_id: channelId }
        });

        if (existingUserChannel) {
            return res.status(400).json({ message: 'Cet utilisateur est déjà membre de ce channel.' });
        }

        // Ajouter l'utilisateur au channel
        await UserChannel.create({ user_id: userId, channel_id: channelId });

        res.status(200).json({ message: 'Utilisateur ajouté au channel avec succès.' });
    } catch (error) {
        res.status(500).json({ message: error.message || 'Erreur lors de l\'ajout de l\'utilisateur au channel.' });
    }
};

/**
 * Obtenir le nombre de messages non lus dans un channel spécifique.
 *
 * @async
 * @function getUnreadMessageCount
 * @param {Object} req - L'objet de requête contenant l'ID du channel.
 * @param {Object} res - L'objet de réponse.
 * @returns {Object} 200 - Le nombre de messages non lus dans le channel.
 * @throws {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la récupération du compteur.
 */
exports.getUnreadMessageCount = async (req, res) => {
    const channelId = req.params.id; 
    const userId = req.auth.userId;

    try {
        const unreadCount = await getUnreadMessageCount(channelId, userId);
        res.status(200).json({ count: unreadCount });
    } catch (error) {
        res.status(500).json({ message: error.message || 'Erreur lors de la récupération du compteur de messages non lus.' });
    }
}

/**
 * Récupérer les channels associés à un utilisateur.
 *
 * @async
 * @function getUserChannels
 * @param {Object} req - L'objet de requête.
 * @param {Object} res - L'objet de réponse.
 * @returns {Object} 200 - Liste des canaux avec le nombre de messages non lus.
 * @throws {Object} 404 - Non trouvé si l'utilisateur n'existe pas.
 * @throws {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la récupération des canaux.
 */
exports.getUserChannels = async (req, res) => {
    try {
        const userId = req.auth.userId;

        // Récupérer les canaux associés à cet utilisateur
        const user = await User.findByPk(userId, {
            include: [{ model: Channel, as: 'Channels' }] // Inclure les canaux associés
        });

        if (!user) {
            return res.status(404).json({ message: 'Utilisateur non trouvé.' });
        }

        const channelsWithUnreadCount = await Promise.all(user.Channels.map(async (channel) => {
            const unreadCount = await getUnreadMessageCount(channel.channel_id, userId);
            return {
                channel_id: channel.channel_id,
                name: channel.name, // Assurez-vous que cette propriété existe
                unreadCount: unreadCount,
                created_by: channel.created_by
            };
        }));

        res.status(200).json(channelsWithUnreadCount);
    } catch (error) {
        res.status(500).json({ message: error.message || 'Erreur lors de la récupération des canaux.' });
    }
};

/**
 * Récupérer les utilisateurs d'un channel spécifique.
 *
 * @async
 * @function getChannelUsers
 * @param {Object} req - L'objet de requête contenant l'ID du channel.
 * @param {Object} res - L'objet de réponse.
 * @returns {Object} 200 - Liste des utilisateurs dans le channel.
 * @throws {Object} 403 - Accès interdit si l'utilisateur n'est pas membre du channel.
 * @throws {Object} 404 - Non trouvé si aucun utilisateur n'est trouvé dans le channel.
 * @throws {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la récupération des utilisateurs.
 */
exports.getChannelUsers = async (req, res) => {
    try {
        const { id } = req.params; // ID du channel
        const userId = req.auth.userId; // ID de l'utilisateur connecté

        // Vérifier si l'utilisateur fait partie du channel
        const userChannel = await UserChannel.findOne({
            where: {
                user_id: userId,
                channel_id: id,
            },
        });

        if (!userChannel) {
            return res.status(403).json({ message: "Vous n'avez pas accès aux utilisateurs de ce channel." });
        }

        // Récupérer les utilisateurs du channel
        const users = await User.findAll({
            include: [{
                model: Channel,
                where: { channel_id: id }, // Filtrer les utilisateurs par channel
                attributes: [] // On ne veut pas les informations de la table de jonction
            }],
            attributes: ['id', 'username', 'avatar'] // Limiter les attributs renvoyés
        });

        if (!users.length) {
            return res.status(404).json({ message: "Aucun utilisateur trouvé dans ce channel." });
        }

        res.status(200).json(users);
    } catch (error) {
        res.status(500).json({ message: error.message || "Erreur lors de la récupération des utilisateurs du channel." });
    }
};


/**
 * Obtenir les messages d'un channel spécifique.
 *
 * @async
 * @function getChannelMessages
 * @param {Object} req - L'objet de requête contenant l'ID du channel.
 * @param {Object} res - L'objet de réponse.
 * @returns {Object} 200 - Liste des messages dans le channel.
 * @throws {Object} 404 - Non trouvé si le channel n'existe pas.
 * @throws {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la récupération des messages.
 */
exports.getChannelMessages = async (req, res) => {
    try {
        const { id } = req.params;
        // Vérifier si le channel existe
        const channel = await Channel.findByPk(id);
        if (!channel) {
            return res.status(404).json({ message: "Channel non trouvé." });
        }
        // Récupérer les messages du channel
        const messages = await PrivateMessage.findAll({
            where: { channel_id: id },
            order: [['createdAt', 'ASC']], // Trier les messages par date croissante
            include: [
                {
                    model: User, // Associe les messages aux utilisateurs pour récupérer leurs infos
                    attributes: ['username', 'avatar'], // On ne sélectionne que ces attributs
                    include: [
                        {
                            model: Inventory, // Inclure l'inventaire de l'utilisateur
                            where: { active: true }, // Filtrer uniquement les articles actifs
                            attributes: ['item_id', 'article_id', 'active'],
                            include: [
                                {
                                    model: Shop, // Détails de l'article
                                    attributes: ['title', 'type', 'content', 'amount']
                                }
                            ],
                            required: false // L'inventaire est facultatif, l'utilisateur sera récupéré même s'il n'a pas d'articles actifs
                        }
                    ]
                }
            ]
        });

        if (!messages.length) {
            return res.status(200).json({ message: "Aucun message trouvé dans ce channel." });
        }

        res.status(200).json(messages);
    } catch (error) {
        res.status(500).json({ message: error.message || 'Une erreur est survenue lors de la récupération des messages.' });
    }
};

/**
 * Quitter un channel.
 *
 * @async
 * @function leaveChannel
 * @param {Object} req - L'objet de requête contenant l'ID du channel à quitter.
 * @param {Object} res - L'objet de réponse.
 * @returns {Object} 200 - Message de succès indiquant que l'utilisateur a quitté le channel.
 * @throws {Object} 404 - Non trouvé si le channel ou l'utilisateur n'est pas membre du channel.
 * @throws {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la tentative de quitter le channel.
 */
exports.leaveChannel = async (req, res) => {
    try {
        const { id } = req.params; // ID du channel à quitter
        const userId = req.auth.userId; // ID de l'utilisateur connecté

        const channel = await Channel.findByPk(id);
        if (!channel) {
            return res.status(404).json({ message: "Channel non trouvé." });
        }
        // Vérifier si l'utilisateur fait partie du channel
        const userChannel = await UserChannel.findOne({
            where: {
                user_id: userId,
                channel_id: id,
            },
        });

        if (!userChannel) {
            return res.status(404).json({ message: "Vous ne faites pas partie de ce channel." });
        }

        // Supprimer l'utilisateur du channel
        await UserChannel.destroy({
            where: {
                user_id: userId,
                channel_id: id,
            },
        });

        res.status(200).json({ message: "Vous avez quitté le channel avec succès." });
    } catch (error) {
        res.status(500).json({ message: error.message || "Une erreur est survenue lors de la tentative de quitter le channel." });
    }
};

/**
 * Supprimer un channel.
 *
 * @async
 * @function deleteChannel
 * @param {Object} req - L'objet de requête contenant l'ID du channel à supprimer.
 * @param {Object} res - L'objet de réponse.
 * @returns {Object} 200 - Message de succès indiquant que le channel a été supprimé.
 * @throws {Object} 404 - Non trouvé si le channel n'existe pas.
 * @throws {Object} 403 - Accès interdit si l'utilisateur n'est pas le créateur du channel.
 * @throws {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la suppression du channel.
 */
exports.deleteChannel = async (req, res) => {
    try {
        const { id } = req.params; // ID du channel à supprimer
        const userId = req.auth.userId; // ID de l'utilisateur connecté

        // Vérifier si le channel existe
        const channel = await Channel.findByPk(id);
        if (!channel) {
            return res.status(404).json({ message: "Channel non trouvé." });
        }

        // Vérifier si l'utilisateur est le créateur du channel
        if (channel.created_by !== userId) {
            return res.status(403).json({ message: "Vous n'avez pas la permission de supprimer ce channel." });
        }

        // Supprimer également toutes les associations dans UserChannel
        await UserChannel.destroy({ where: { channel_id: id } });
        
        // Supprimer le channel
        await Channel.destroy({ where: { channel_id: id } });

        res.status(200).json({ message: "Channel supprimé avec succès." });
    } catch (error) {
        res.status(500).json({ message: error.message || "Une erreur est survenue lors de la tentative de supprimer le channel." });
    }
};
