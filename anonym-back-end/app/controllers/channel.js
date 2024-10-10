const { Channel, PrivateMessage, User, UserChannel, Inventory, Shop } = require('../models');
const { Op } = require('sequelize');

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

// Créer un nouveau canal
exports.create = async (req, res) => {
    try {
        const { name, description } = req.body;
        const userId = req.auth.userId; 

        if(!name) {
            return res.status(400).json({ message: 'Le nom du groupe est requis' });
        }

        // Créer le canal
        const channel = await Channel.create({ 
            name, 
            description,
            created_by: userId
        });

        // Associer le canal au créateur (utilisateur actuel)
        await UserChannel.create({ user_id: userId, channel_id: channel.channel_id });

        res.status(201).json(channel);
    } catch (error) {
        res.status(500).json({ message: error.message || 'Une erreur est survenue lors de la création du canal.' });
    }
};

exports.invite = async (req, res) => {
    try {
        const { channelId, userId } = req.body;

        // Vérifier si l'utilisateur est déjà membre du canal
        const existingUserChannel = await UserChannel.findOne({
            where: { user_id: userId, channel_id: channelId }
        });

        if (existingUserChannel) {
            return res.status(400).json({ message: 'Cet utilisateur est déjà membre de ce canal.' });
        }

        // Ajouter l'utilisateur au canal
        await UserChannel.create({ user_id: userId, channel_id: channelId });

        res.status(200).json({ message: 'Utilisateur ajouté au canal avec succès.' });
    } catch (error) {
        res.status(500).json({ message: error.message || 'Erreur lors de l\'ajout de l\'utilisateur au canal.' });
    }
};

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
        console.error(error);
        res.status(500).json({ message: error.message || 'Erreur lors de la récupération des canaux.' });
    }
};


// Récupérer les utilisateurs d'un canal
exports.getChannelUsers = async (req, res) => {
    try {
        const { id } = req.params; // ID du canal
        const userId = req.auth.userId; // ID de l'utilisateur connecté

        // Vérifier si l'utilisateur fait partie du canal
        const userChannel = await UserChannel.findOne({
            where: {
                user_id: userId,
                channel_id: id,
            },
        });

        if (!userChannel) {
            return res.status(403).json({ message: "Vous n'avez pas accès aux utilisateurs de ce canal." });
        }

        // Récupérer les utilisateurs du canal
        const users = await User.findAll({
            include: [{
                model: Channel,
                where: { channel_id: id }, // Filtrer les utilisateurs par canal
                attributes: [] // On ne veut pas les informations de la table de jonction
            }],
            attributes: ['id', 'username', 'avatar'] // Limiter les attributs renvoyés
        });

        if (!users.length) {
            return res.status(404).json({ message: "Aucun utilisateur trouvé dans ce canal." });
        }

        res.status(200).json(users);
    } catch (error) {
        res.status(500).json({ message: error.message || "Erreur lors de la récupération des utilisateurs du canal." });
    }
};


// Obtenir les messages d'un canal spécifique
exports.getChannelMessages = async (req, res) => {
    try {
        const { id } = req.params;
        // Vérifier si le canal existe
        const channel = await Channel.findByPk(id);
        if (!channel) {
            return res.status(404).json({ message: "Canal non trouvé." });
        }
        // Récupérer les messages du canal
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
            return res.status(200).json({ message: "Aucun message trouvé dans ce canal." });
        }

        res.status(200).json(messages);
    } catch (error) {
        res.status(500).json({ message: error.message || 'Une erreur est survenue lors de la récupération des messages.' });
    }
};

// Quitter un canal
exports.leaveChannel = async (req, res) => {
    try {
        const { id } = req.params; // ID du canal à quitter
        const userId = req.auth.userId; // ID de l'utilisateur connecté

        const channel = await Channel.findByPk(id);
        if (!channel) {
            return res.status(404).json({ message: "Canal non trouvé." });
        }
        // Vérifier si l'utilisateur fait partie du canal
        const userChannel = await UserChannel.findOne({
            where: {
                user_id: userId,
                channel_id: id,
            },
        });

        if (!userChannel) {
            return res.status(404).json({ message: "Vous ne faites pas partie de ce canal." });
        }

        // Supprimer l'utilisateur du canal
        await UserChannel.destroy({
            where: {
                user_id: userId,
                channel_id: id,
            },
        });

        res.status(200).json({ message: "Vous avez quitté le canal avec succès." });
    } catch (error) {
        res.status(500).json({ message: error.message || "Une erreur est survenue lors de la tentative de quitter le canal." });
    }
};

// Supprimer un canal
exports.deleteChannel = async (req, res) => {
    try {
        const { id } = req.params; // ID du canal à supprimer
        const userId = req.auth.userId; // ID de l'utilisateur connecté

        // Vérifier si le canal existe
        const channel = await Channel.findByPk(id);
        if (!channel) {
            return res.status(404).json({ message: "Canal non trouvé." });
        }

        // Vérifier si l'utilisateur est le créateur du canal
        if (channel.created_by !== userId) {
            return res.status(403).json({ message: "Vous n'avez pas la permission de supprimer ce canal." });
        }

        // Supprimer également toutes les associations dans UserChannel
        await UserChannel.destroy({ where: { channel_id: id } });
        
        // Supprimer le canal
        await Channel.destroy({ where: { channel_id: id } });

        res.status(200).json({ message: "Canal supprimé avec succès." });
    } catch (error) {
        res.status(500).json({ message: error.message || "Une erreur est survenue lors de la tentative de supprimer le canal." });
    }
};
