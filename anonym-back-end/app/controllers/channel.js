const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const { Channel, PrivateMessage, User, UserChannel, Inventory, Shop, ChannelInvite } = require('../models');
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

const isUserChannelMember = async (channelId, userId) => {
    const membership = await UserChannel.findOne({
        where: { channel_id: channelId, user_id: userId }
    });
    return Boolean(membership);
};

const buildInviteCode = () => crypto.randomBytes(24).toString('hex');
const parseMaybeJsonArray = (value) => {
    if (Array.isArray(value)) return value;
    if (typeof value === 'string') {
        try {
            const parsed = JSON.parse(value);
            return Array.isArray(parsed) ? parsed : [];
        } catch {
            return [];
        }
    }
    return [];
};

exports.create = async (req, res) => {
    try {
        const { name, description, channelType = 'GROUP', visibility = 'PRIVATE' } = req.body;
        const memberIds = parseMaybeJsonArray(req.body.memberIds);
        const userId = req.auth.userId;
        const uploadedCoverImage = req.file
            ? `${req.protocol}://${req.get("host")}/uploads/channels/covers/${req.file.filename}`
            : null;

        if (!['GROUP', 'PRIVATE_DM'].includes(channelType)) {
            return res.status(400).json({ message: 'Type de channel invalide.' });
        }

        if (!['PUBLIC', 'PRIVATE'].includes(visibility)) {
            return res.status(400).json({ message: 'Visibilite invalide.' });
        }

        if (channelType === 'GROUP' && !name) {
            return res.status(400).json({ message: 'Le nom du groupe est requis' });
        }

        if (channelType === 'PRIVATE_DM' && (!Array.isArray(memberIds) || memberIds.length !== 1)) {
            return res.status(400).json({ message: 'Un message prive doit contenir exactement 2 users.' });
        }

        let targetUserId = null;
        if (channelType === 'PRIVATE_DM') {
            targetUserId = parseInt(memberIds[0], 10);
            if (!Number.isInteger(targetUserId) || targetUserId === userId) {
                return res.status(400).json({ message: 'Utilisateur prive invalide.' });
            }

            const existingDm = await Channel.findOne({
                where: { channel_type: 'PRIVATE_DM' },
                include: [
                    {
                        model: User,
                        as: 'Users',
                        attributes: ['id'],
                        through: { attributes: [] },
                        where: { id: { [Op.in]: [userId, targetUserId] } },
                        required: true
                    }
                ],
                group: ['Channel.channel_id'],
                having: Channel.sequelize.literal('COUNT(DISTINCT `Users`.`id`) = 2')
            });

            if (existingDm) {
                return res.status(200).json(existingDm);
            }
        }

        const finalVisibility = channelType === 'PRIVATE_DM' ? 'PRIVATE' : visibility;
        const coverImage = channelType === 'GROUP' ? uploadedCoverImage : null;

        const channel = await Channel.create({
            name: channelType === 'PRIVATE_DM' ? null : name,
            description,
            cover_image: coverImage,
            channel_type: channelType,
            visibility: finalVisibility,
            created_by: userId
        });

        await UserChannel.create({ user_id: userId, channel_id: channel.channel_id });

        if (channelType === 'PRIVATE_DM') {
            await UserChannel.create({ user_id: targetUserId, channel_id: channel.channel_id });
        }

        res.status(201).json(channel);
    } catch (error) {
        res.status(500).json({ message: error.message || 'Une erreur est survenue lors de la creation du channel.' });
    }
};

exports.updateCoverImage = async (req, res) => {
    try {
        const channelId = parseInt(req.params.id, 10);
        const userId = req.auth.userId;

        if (!req.file) {
            return res.status(400).json({ message: 'Image requise (champ: image).' });
        }

        const channel = await Channel.findByPk(channelId);
        if (!channel) {
            return res.status(404).json({ message: 'Channel non trouve.' });
        }

        if (channel.created_by !== userId) {
            return res.status(403).json({ message: "Vous n'avez pas la permission de modifier la couverture." });
        }

        if (channel.cover_image) {
            const oldPath = path.join(__dirname, '../../uploads/channels/covers', path.basename(channel.cover_image));
            if (fs.existsSync(oldPath)) {
                fs.unlinkSync(oldPath);
            }
        }

        channel.cover_image = `${req.protocol}://${req.get("host")}/uploads/channels/covers/${req.file.filename}`;
        await channel.save();

        return res.status(200).json({
            channel_id: channel.channel_id,
            cover_image: channel.cover_image
        });
    } catch (error) {
        return res.status(500).json({ message: error.message || 'Erreur lors de la mise a jour de la couverture.' });
    }
};

exports.updateChannel = async (req, res) => {
    try {
        const channelId = parseInt(req.params.id, 10);
        const userId = req.auth.userId;
        const { name, description, visibility } = req.body;

        const channel = await Channel.findByPk(channelId);
        if (!channel) {
            return res.status(404).json({ message: 'Channel non trouve.' });
        }

        if (channel.created_by !== userId) {
            return res.status(403).json({ message: "Vous n'avez pas la permission de modifier ce channel." });
        }

        if (channel.channel_type !== 'GROUP') {
            return res.status(400).json({ message: 'Seuls les groupes peuvent etre modifies.' });
        }

        if (visibility !== undefined && !['PUBLIC', 'PRIVATE'].includes(visibility)) {
            return res.status(400).json({ message: 'Visibilite invalide.' });
        }

        if (name !== undefined) {
            if (!name || !name.trim()) {
                return res.status(400).json({ message: 'Le nom du groupe est requis.' });
            }
            channel.name = name.trim();
        }

        if (description !== undefined) {
            channel.description = description;
        }

        if (visibility !== undefined) {
            channel.visibility = visibility;
        }

        await channel.save();

        return res.status(200).json({
            channel_id: channel.channel_id,
            name: channel.name,
            description: channel.description,
            visibility: channel.visibility,
            cover_image: channel.cover_image,
            channel_type: channel.channel_type,
            created_by: channel.created_by
        });
    } catch (error) {
        return res.status(500).json({ message: error.message || 'Erreur lors de la mise a jour du channel.' });
    }
};

exports.invite = async (req, res) => {
    try {
        const { channelId, userId } = req.body;
        const requesterId = req.auth.userId;

        const channel = await Channel.findByPk(channelId);
        if (!channel) {
            return res.status(404).json({ message: 'Channel non trouve.' });
        }

        if (channel.channel_type === 'PRIVATE_DM') {
            return res.status(400).json({ message: 'Impossible d inviter dans un message prive.' });
        }

        const isMember = await isUserChannelMember(channelId, requesterId);
        if (!isMember) {
            return res.status(403).json({ message: 'Vous ne faites pas partie de ce channel.' });
        }

        const existingUserChannel = await UserChannel.findOne({
            where: { user_id: userId, channel_id: channelId }
        });

        if (existingUserChannel) {
            return res.status(400).json({ message: 'Cet utilisateur est deja membre de ce channel.' });
        }

        await UserChannel.create({ user_id: userId, channel_id: channelId });

        res.status(200).json({ message: 'Utilisateur ajoute au channel avec succes.' });
    } catch (error) {
        res.status(500).json({ message: error.message || 'Erreur lors de l ajout de l utilisateur au channel.' });
    }
};

exports.createInviteLink = async (req, res) => {
    try {
        const channelId = parseInt(req.params.id, 10);
        const userId = req.auth.userId;
        const { mode = 'PERMANENT', expiresInMinutes = 60 } = req.body;

        const channel = await Channel.findByPk(channelId);
        if (!channel) {
            return res.status(404).json({ message: 'Channel non trouve.' });
        }

        if (channel.channel_type === 'PRIVATE_DM') {
            return res.status(400).json({ message: 'Pas de lien d invitation pour les messages prives.' });
        }

        const isMember = await isUserChannelMember(channelId, userId);
        if (!isMember) {
            return res.status(403).json({ message: 'Vous ne faites pas partie de ce channel.' });
        }

        if (!['PERMANENT', 'TEMPORARY'].includes(mode)) {
            return res.status(400).json({ message: 'Mode invitation invalide.' });
        }

        const invite = await ChannelInvite.create({
            channel_id: channelId,
            code: buildInviteCode(),
            created_by: userId,
            expires_at: mode === 'TEMPORARY' ? new Date(Date.now() + parseInt(expiresInMinutes, 10) * 60 * 1000) : null,
            max_uses: mode === 'TEMPORARY' ? 1 : null,
            uses_count: 0,
            is_active: true
        });

        return res.status(201).json(invite);
    } catch (error) {
        return res.status(500).json({ message: error.message || 'Erreur lors de la creation de l invitation.' });
    }
};

exports.joinPublicChannel = async (req, res) => {
    try {
        const channelId = parseInt(req.params.id, 10);
        const userId = req.auth.userId;

        const channel = await Channel.findByPk(channelId);
        if (!channel) {
            return res.status(404).json({ message: 'Channel non trouve.' });
        }

        if (channel.channel_type !== 'GROUP' || channel.visibility !== 'PUBLIC') {
            return res.status(403).json({ message: 'Ce channel ne peut pas etre rejoint publiquement.' });
        }

        const existing = await UserChannel.findOne({ where: { user_id: userId, channel_id: channelId } });
        if (existing) {
            return res.status(200).json({ message: 'Vous etes deja dans ce channel.' });
        }

        await UserChannel.create({ user_id: userId, channel_id: channelId });
        return res.status(200).json({ message: 'Channel rejoint avec succes.' });
    } catch (error) {
        return res.status(500).json({ message: error.message || 'Erreur lors de la tentative de rejoindre ce channel.' });
    }
};

exports.joinByInviteCode = async (req, res) => {
    try {
        const { code } = req.body;
        const userId = req.auth.userId;

        if (!code) {
            return res.status(400).json({ message: 'Le code d invitation est requis.' });
        }

        const invite = await ChannelInvite.findOne({ where: { code, is_active: true } });
        if (!invite) {
            return res.status(404).json({ message: 'Invitation invalide ou expiree.' });
        }

        if (invite.expires_at && new Date(invite.expires_at) < new Date()) {
            invite.is_active = false;
            await invite.save();
            return res.status(400).json({ message: 'Invitation expiree.' });
        }

        if (invite.max_uses !== null && invite.uses_count >= invite.max_uses) {
            invite.is_active = false;
            await invite.save();
            return res.status(400).json({ message: 'Invitation deja utilisee.' });
        }

        const channel = await Channel.findByPk(invite.channel_id);
        if (!channel || channel.channel_type !== 'GROUP') {
            return res.status(404).json({ message: 'Channel cible introuvable.' });
        }

        const existing = await UserChannel.findOne({ where: { user_id: userId, channel_id: channel.channel_id } });
        if (existing) {
            return res.status(200).json({ message: 'Vous etes deja dans ce channel.' });
        }

        await UserChannel.create({ user_id: userId, channel_id: channel.channel_id });

        invite.uses_count += 1;
        if (invite.max_uses !== null && invite.uses_count >= invite.max_uses) {
            invite.is_active = false;
        }
        await invite.save();

        return res.status(200).json({ message: 'Channel rejoint via invitation.', channel_id: channel.channel_id });
    } catch (error) {
        return res.status(500).json({ message: error.message || 'Erreur lors du join via invitation.' });
    }
};

exports.getUnreadMessageCount = async (req, res) => {
    const channelId = req.params.id;
    const userId = req.auth.userId;

    try {
        const unreadCount = await getUnreadMessageCount(channelId, userId);
        res.status(200).json({ count: unreadCount });
    } catch (error) {
        res.status(500).json({ message: error.message || 'Erreur lors de la recuperation du compteur de messages non lus.' });
    }
};

exports.getUserChannels = async (req, res) => {
    try {
        const userId = req.auth.userId;

        const user = await User.findByPk(userId, {
            include: [{ model: Channel, as: 'Channels' }]
        });

        if (!user) {
            return res.status(404).json({ message: 'Utilisateur non trouve.' });
        }

        const channelsWithUnreadCount = await Promise.all(user.Channels.map(async (channel) => {
            const unreadCount = await getUnreadMessageCount(channel.channel_id, userId);
            return {
                channel_id: channel.channel_id,
                name: channel.name,
                unreadCount,
                created_by: channel.created_by,
                cover_image: channel.cover_image,
                channel_type: channel.channel_type,
                visibility: channel.visibility
            };
        }));

        res.status(200).json(channelsWithUnreadCount);
    } catch (error) {
        res.status(500).json({ message: error.message || 'Erreur lors de la recuperation des canaux.' });
    }
};

exports.getChannelUsers = async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.auth.userId;

        const isMember = await isUserChannelMember(id, userId);
        if (!isMember) {
            return res.status(403).json({ message: "Vous n'avez pas acces aux utilisateurs de ce channel." });
        }

        const users = await User.findAll({
            include: [{
                model: Channel,
                where: { channel_id: id },
                attributes: []
            },
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
            }],
            attributes: ['id', 'username', 'avatar']
        });

        if (!users.length) {
            return res.status(404).json({ message: 'Aucun utilisateur trouve dans ce channel.' });
        }

        res.status(200).json(users);
    } catch (error) {
        res.status(500).json({ message: error.message || 'Erreur lors de la recuperation des utilisateurs du channel.' });
    }
};

exports.getChannelMessages = async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.auth.userId;

        const channel = await Channel.findByPk(id);
        if (!channel) {
            return res.status(404).json({ message: 'Channel non trouve.' });
        }

        const isMember = await isUserChannelMember(id, userId);
        if (!isMember) {
            return res.status(403).json({ message: 'Vous ne faites pas partie de ce channel.' });
        }

        const messages = await PrivateMessage.findAll({
            where: { channel_id: id },
            order: [['createdAt', 'ASC']],
            include: [
                {
                    model: User,
                    attributes: ['username', 'avatar'],
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
                }
            ]
        });

        if (!messages.length) {
            return res.status(200).json({ message: 'Aucun message trouve dans ce channel.' });
        }

        res.status(200).json(messages);
    } catch (error) {
        res.status(500).json({ message: error.message || 'Une erreur est survenue lors de la recuperation des messages.' });
    }
};

exports.leaveChannel = async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.auth.userId;

        const channel = await Channel.findByPk(id);
        if (!channel) {
            return res.status(404).json({ message: 'Channel non trouve.' });
        }

        if (channel.channel_type === 'PRIVATE_DM') {
            return res.status(400).json({ message: 'Un message prive ne peut pas etre quitte via cette route.' });
        }

        const userChannel = await UserChannel.findOne({
            where: {
                user_id: userId,
                channel_id: id,
            },
        });

        if (!userChannel) {
            return res.status(404).json({ message: 'Vous ne faites pas partie de ce channel.' });
        }

        await UserChannel.destroy({
            where: {
                user_id: userId,
                channel_id: id,
            },
        });

        res.status(200).json({ message: 'Vous avez quitte le channel avec succes.' });
    } catch (error) {
        res.status(500).json({ message: error.message || 'Une erreur est survenue lors de la tentative de quitter le channel.' });
    }
};

exports.deleteChannel = async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.auth.userId;

        const channel = await Channel.findByPk(id);
        if (!channel) {
            return res.status(404).json({ message: 'Channel non trouve.' });
        }

        if (channel.created_by !== userId) {
            return res.status(403).json({ message: "Vous n'avez pas la permission de supprimer ce channel." });
        }

        if (channel.channel_type === 'PRIVATE_DM') {
            return res.status(400).json({ message: 'Un message prive ne peut pas etre supprime.' });
        }

        await UserChannel.destroy({ where: { channel_id: id } });
        await ChannelInvite.destroy({ where: { channel_id: id } });
        await Channel.destroy({ where: { channel_id: id } });

        res.status(200).json({ message: 'Channel supprime avec succes.' });
    } catch (error) {
        res.status(500).json({ message: error.message || 'Une erreur est survenue lors de la tentative de supprimer le channel.' });
    }
};
