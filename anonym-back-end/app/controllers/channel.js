const crypto = require('crypto');
const { Channel, PrivateMessage, User, UserChannel, Inventory, Shop, ChannelInvite, Friend } = require('../models');
const { Op } = require('sequelize');
const { deleteUploadFileIfExists, deleteUploadFiles } = require('../utils/fileCleanup');
const { sendPushToUsers } = require('../utils/pushNotifications');
let hasAllowNonFriendDmsColumnCache = null;

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
const groupInvitePayloadPrefix = 'ANONYM_GROUP_INVITE:';
const encodeGroupInvitePayload = ({
    channelId,
    channelName,
    channelDescription,
    channelCoverImage,
    channelVisibility,
    inviteCode,
    invitedByUserId,
    invitedByUsername
}) => {
    return `${groupInvitePayloadPrefix}${JSON.stringify({
        channelId,
        channelName,
        channelDescription: channelDescription || '',
        channelCoverImage: channelCoverImage || null,
        channelVisibility: channelVisibility || 'PRIVATE',
        inviteCode,
        invitedByUserId,
        invitedByUsername
    })}`;
};
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

const computeChannelReputationScore = async (channelId) => {
    const [messageCount, participantCount] = await Promise.all([
        PrivateMessage.count({ where: { channel_id: channelId } }),
        UserChannel.count({ where: { channel_id: channelId } })
    ]);

    return (messageCount * 1) + (participantCount * 2);
};

const refreshReputationScores = async (channels) => {
    if (!channels.length) return [];

    const channelsWithScores = await Promise.all(channels.map(async (channel) => {
        const reputationScore = await computeChannelReputationScore(channel.channel_id);
        if (channel.reputation_score !== reputationScore) {
            await channel.update({ reputation_score: reputationScore });
        }
        return { channel, reputationScore };
    }));

    return channelsWithScores;
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

    const reputationScore = await computeChannelReputationScore(channelId);
    if (channel.reputation_score !== reputationScore) {
        await channel.update({ reputation_score: reputationScore });
    }
    return reputationScore;
};

const resolveDirectMessageChannel = async (userAId, userBId) => {
    const candidateMemberships = await UserChannel.findAll({
        attributes: [
            'channel_id',
            [UserChannel.sequelize.fn('COUNT', UserChannel.sequelize.fn('DISTINCT', UserChannel.sequelize.col('user_id'))), 'memberCount']
        ],
        where: {
            user_id: { [Op.in]: [userAId, userBId] }
        },
        group: ['channel_id'],
        having: UserChannel.sequelize.literal('COUNT(DISTINCT user_id) = 2'),
        raw: true
    });

    if (candidateMemberships.length > 0) {
        const candidateChannelIds = candidateMemberships.map((row) => row.channel_id);
        const existingDm = await Channel.findOne({
            where: {
                channel_id: { [Op.in]: candidateChannelIds },
                channel_type: 'PRIVATE_DM'
            },
            order: [['channel_id', 'ASC']]
        });

        if (existingDm) {
            await UserChannel.findOrCreate({ where: { user_id: userAId, channel_id: existingDm.channel_id } });
            await UserChannel.findOrCreate({ where: { user_id: userBId, channel_id: existingDm.channel_id } });
            return existingDm;
        }
    }

    const dmChannel = await Channel.create({
        name: null,
        description: null,
        cover_image: null,
        channel_type: 'PRIVATE_DM',
        visibility: 'PRIVATE',
        created_by: userAId
    });

    await UserChannel.findOrCreate({ where: { user_id: userAId, channel_id: dmChannel.channel_id } });
    await UserChannel.findOrCreate({ where: { user_id: userBId, channel_id: dmChannel.channel_id } });
    return dmChannel;
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

        if (channelType === 'PRIVATE_DM' && memberIds.length !== 1) {
            return res.status(400).json({ message: 'Un message prive doit contenir exactement 2 users.' });
        }

        let targetUserId = null;
        if (channelType === 'PRIVATE_DM') {
            targetUserId = parseInt(memberIds[0], 10);
            if (!Number.isInteger(targetUserId) || targetUserId === userId) {
                return res.status(400).json({ message: 'Utilisateur prive invalide.' });
            }

            const blockedRelationshipExists = await hasBlockedRelationship(userId, targetUserId);
            if (blockedRelationshipExists) {
                return res.status(403).json({
                    message: 'Impossible de creer un message prive: cette relation est bloquee.'
                });
            }

            const allowNonFriendDmsColumnExists = await hasAllowNonFriendDmsColumn();
            const targetUser = await User.findByPk(targetUserId, {
                attributes: allowNonFriendDmsColumnExists ? ['id', 'allow_non_friend_dms'] : ['id']
            });
            if (!targetUser) {
                return res.status(404).json({ message: 'Utilisateur introuvable.' });
            }

            const allowNonFriendDms = allowNonFriendDmsColumnExists
                ? targetUser.allow_non_friend_dms
                : true;

            if (!allowNonFriendDms) {
                const activeFriendship = await Friend.findOne({
                    where: {
                        status: 'ACTIVE',
                        [Op.or]: [
                            { user_id: userId, friend_id: targetUserId },
                            { user_id: targetUserId, friend_id: userId }
                        ]
                    }
                });

                if (!activeFriendship) {
                    return res.status(403).json({
                        message: 'Cet utilisateur accepte uniquement les messages prives de ses amis.'
                    });
                }
            }

            const candidateMemberships = await UserChannel.findAll({
                attributes: [
                    'channel_id',
                    [UserChannel.sequelize.fn('COUNT', UserChannel.sequelize.fn('DISTINCT', UserChannel.sequelize.col('user_id'))), 'memberCount']
                ],
                where: {
                    user_id: { [Op.in]: [userId, targetUserId] }
                },
                group: ['channel_id'],
                having: UserChannel.sequelize.literal('COUNT(DISTINCT user_id) = 2'),
                raw: true
            });

            if (candidateMemberships.length > 0) {
                const candidateChannelIds = candidateMemberships.map((row) => row.channel_id);
                const existingDm = await Channel.findOne({
                    where: {
                        channel_id: { [Op.in]: candidateChannelIds },
                        channel_type: 'PRIVATE_DM'
                    },
                    order: [['channel_id', 'ASC']]
                });

                if (existingDm) {
                    return res.status(200).json(existingDm);
                }
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

        await updateChannelReputationScore(channel.channel_id);

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

        deleteUploadFileIfExists(channel.cover_image);

        channel.cover_image = `${req.protocol}://${req.get("host")}/uploads/channels/covers/${req.file.filename}`;
        await channel.save();
        await updateChannelReputationScore(channel.channel_id);

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
        const invitedUserId = parseInt(userId, 10);

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

        if (!Number.isInteger(invitedUserId) || invitedUserId <= 0) {
            return res.status(400).json({ message: 'Utilisateur invite invalide.' });
        }

        const invitedUser = await User.findByPk(invitedUserId, {
            attributes: ['id', 'username', 'avatar']
        });
        if (!invitedUser) {
            return res.status(404).json({ message: 'Utilisateur invite introuvable.' });
        }

        const existingUserChannel = await UserChannel.findOne({
            where: { user_id: invitedUserId, channel_id: channelId }
        });

        if (existingUserChannel) {
            return res.status(400).json({ message: 'Cet utilisateur est deja membre de ce channel.' });
        }

        const blockedRelationshipExists = await hasBlockedRelationship(requesterId, invitedUserId);
        if (blockedRelationshipExists) {
            const io = req.app?.locals?.io;
            if (io) {
                io.to(`user:${invitedUserId}`).emit('channelInvited', {
                    channelId: Number(channelId),
                    channelName: channel.name || 'groupe',
                    invitedBy: requesterId
                });
            }

            return res.status(200).json({
                message: 'Invitation envoyee.'
            });
        }

        const requester = await User.findByPk(requesterId, {
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

        const dmChannel = await resolveDirectMessageChannel(requesterId, invitedUserId);
        const invite = await ChannelInvite.create({
            channel_id: channelId,
            code: buildInviteCode(),
            created_by: requesterId,
            expires_at: new Date(Date.now() + (7 * 24 * 60 * 60 * 1000)),
            max_uses: 1,
            uses_count: 0,
            is_active: true
        });
        const invitationContent = encodeGroupInvitePayload({
            channelId: Number(channelId),
            channelName: channel.name || 'groupe',
            channelDescription: channel.description || '',
            channelCoverImage: channel.cover_image || null,
            channelVisibility: channel.visibility || 'PRIVATE',
            inviteCode: invite.code,
            invitedByUserId: requesterId,
            invitedByUsername: requester?.username || 'Un utilisateur'
        });
        const invitationMessage = await PrivateMessage.create({
            sender_id: requesterId,
            content: invitationContent,
            image_url: null,
            channel_id: dmChannel.channel_id,
            status: 'unread',
            createdAt: new Date()
        });

        const io = req.app?.locals?.io;
        if (io) {
            const invitationPayload = {
                id: invitationMessage.message_id,
                content: invitationMessage.content,
                imageUrl: invitationMessage.image_url,
                channelId: dmChannel.channel_id,
                sender: requester,
                createdAt: invitationMessage.createdAt
            };
            io.to(`user:${requesterId}`).emit('newMessage', invitationPayload);
            io.to(`user:${invitedUserId}`).emit('newMessage', invitationPayload);

            io.to(`user:${invitedUserId}`).emit('channelInvited', {
                channelId: Number(channelId),
                channelName: channel.name || 'groupe',
                invitedBy: requesterId,
                inviteCode: invite.code
            });
        }

        await sendPushToUsers({
            userIds: [invitedUserId],
            excludeUserId: requesterId,
            data: {
                event: 'newMessage',
                id: invitationMessage.message_id,
                channelId: dmChannel.channel_id,
                senderId: requesterId,
                senderUsername: requester?.username || ''
            }
        });

        res.status(200).json({
            message: 'Invitation envoyee.',
            inviteCode: invite.code
        });
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
        await updateChannelReputationScore(channelId);
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
        await updateChannelReputationScore(channel.channel_id);

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
        const hasExplicitFilter = typeof req.query.filter === 'string';
        const filter = hasExplicitFilter
            ? req.query.filter.trim().toLowerCase()
            : 'all';

        if (!['all', 'joined', 'discover'].includes(filter)) {
            return res.status(400).json({ message: "Filtre invalide. Utilisez 'all', 'joined' ou 'discover'." });
        }

        const user = await User.findByPk(userId, {
            include: [{ model: Channel, as: 'Channels' }]
        });

        if (!user) {
            return res.status(404).json({ message: 'Utilisateur non trouve.' });
        }

        const joinedChannels = user.Channels;

        const joinedChannelIds = new Set(joinedChannels.map((channel) => channel.channel_id));

        const dmChannelIds = joinedChannels
            .filter((channel) => channel.channel_type === 'PRIVATE_DM')
            .map((channel) => channel.channel_id);

        const dmPeerByChannelId = {};
        if (dmChannelIds.length > 0) {
            const dmUsers = await User.findAll({
                attributes: ['id', 'username', 'avatar'],
                include: [
                    {
                        model: Channel,
                        attributes: ['channel_id'],
                        where: { channel_id: { [Op.in]: dmChannelIds } },
                        through: { attributes: [] },
                        required: true
                    },
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
            });

            for (const dmUser of dmUsers) {
                if (dmUser.id === userId) continue;
                for (const dmChannel of dmUser.Channels || []) {
                    if (!dmPeerByChannelId[dmChannel.channel_id]) {
                        dmPeerByChannelId[dmChannel.channel_id] = {
                            id: dmUser.id,
                            username: dmUser.username,
                            avatar: dmUser.avatar,
                            Inventories: dmUser.Inventories || []
                        };
                    }
                }
            }
        }

        const joinedChannelsWithUnreadCount = await Promise.all(joinedChannels.map(async (channel) => {
            const unreadCount = await getUnreadMessageCount(channel.channel_id, userId);
            return {
                channel_id: channel.channel_id,
                name: channel.name,
                unreadCount,
                created_by: channel.created_by,
                cover_image: channel.cover_image,
                channel_type: channel.channel_type,
                visibility: channel.visibility,
                is_joined: true,
                list_category: 'joined',
                dm_peer: channel.channel_type === 'PRIVATE_DM'
                    ? (dmPeerByChannelId[channel.channel_id] || null)
                    : null
            };
        }));
        const publicDiscoverChannels = await Channel.findAll({
            where: {
                channel_type: 'GROUP',
                visibility: 'PUBLIC'
            },
            order: [['reputation_score', 'DESC'], ['createdAt', 'DESC']]
        });

        const discoverChannelsWithScores = await refreshReputationScores(publicDiscoverChannels);
        const discoverChannels = discoverChannelsWithScores
            .sort((a, b) => b.reputationScore - a.reputationScore)
            .slice(0, 10)
            .map(({ channel, reputationScore }) => ({
            channel_id: channel.channel_id,
            name: channel.name,
            unreadCount: 0,
            created_by: channel.created_by,
            cover_image: channel.cover_image,
            channel_type: channel.channel_type,
            visibility: channel.visibility,
            reputation_score: reputationScore,
            is_joined: joinedChannelIds.has(channel.channel_id),
            list_category: 'discover',
            dm_peer: null
        }));

        const mergedChannels = filter === 'discover'
            ? discoverChannels
            : [
                ...joinedChannelsWithUnreadCount,
                ...discoverChannels.filter((channel) => !joinedChannelIds.has(channel.channel_id))
            ];

        const channelsWithFilter = mergedChannels.filter((channel) => {
            if (filter === 'discover' && channel.channel_type === 'PRIVATE_DM') return false;
            if (filter === 'all' && hasExplicitFilter && channel.channel_type === 'PRIVATE_DM') return false;
            if (filter === 'joined') return channel.is_joined === true;
            if (filter === 'discover') return channel.list_category === 'discover';
            return true;
        });

        res.status(200).json(channelsWithFilter);
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

exports.removeMember = async (req, res) => {
    try {
        const channelId = parseInt(req.params.id, 10);
        const targetUserId = parseInt(req.params.userId, 10);
        const requesterId = req.auth.userId;

        if (!Number.isInteger(channelId) || channelId <= 0) {
            return res.status(400).json({ message: 'Channel invalide.' });
        }

        if (!Number.isInteger(targetUserId) || targetUserId <= 0) {
            return res.status(400).json({ message: 'Utilisateur invalide.' });
        }

        const channel = await Channel.findByPk(channelId);
        if (!channel) {
            return res.status(404).json({ message: 'Channel non trouve.' });
        }

        if (channel.channel_type !== 'GROUP') {
            return res.status(400).json({ message: 'Seuls les groupes permettent l exclusion d un membre.' });
        }

        if (channel.created_by !== requesterId) {
            return res.status(403).json({ message: "Seul l hote du groupe peut exclure un membre." });
        }

        if (targetUserId === requesterId) {
            return res.status(400).json({ message: 'L hote ne peut pas s exclure lui-meme via cette action.' });
        }

        const membership = await UserChannel.findOne({
            where: {
                channel_id: channelId,
                user_id: targetUserId
            }
        });

        if (!membership) {
            return res.status(404).json({ message: 'Membre introuvable dans ce groupe.' });
        }

        await membership.destroy();
        await updateChannelReputationScore(channelId);

        const io = req.app?.locals?.io;
        if (io) {
            const payload = {
                channelId,
                removedUserId: targetUserId,
                removedBy: requesterId,
                removedAt: new Date().toISOString()
            };

            io.to(channelId).emit('channelMemberRemoved', payload);
            io.to(`user:${requesterId}`).emit('channelMemberRemoved', payload);
            io.to(`user:${targetUserId}`).emit('channelMemberRemoved', payload);
        }

        return res.status(200).json({ message: 'Membre exclu du groupe avec succes.' });
    } catch (error) {
        return res.status(500).json({ message: error.message || 'Erreur lors de l exclusion du membre.' });
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
        await updateChannelReputationScore(id);

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

        const messagesWithImages = await PrivateMessage.findAll({
            where: {
                channel_id: id,
                image_url: { [Op.ne]: null }
            },
            attributes: ['image_url'],
            raw: true
        });

        deleteUploadFiles([
            channel.cover_image,
            ...messagesWithImages.map((message) => message.image_url)
        ]);

        await UserChannel.destroy({ where: { channel_id: id } });
        await ChannelInvite.destroy({ where: { channel_id: id } });
        await Channel.destroy({ where: { channel_id: id } });

        res.status(200).json({ message: 'Channel supprime avec succes.' });
    } catch (error) {
        res.status(500).json({ message: error.message || 'Une erreur est survenue lors de la tentative de supprimer le channel.' });
    }
};
