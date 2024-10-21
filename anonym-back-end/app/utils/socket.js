const { PrivateMessage, User, Inventory, Shop, Channel } = require('../models');
const { Op } = require('sequelize'); // Assurez-vous d'importer Op pour les requêtes


/**
 * Récupère le nombre de messages non lus dans un canal donné, pour un utilisateur spécifique.
 * 
 * @async
 * @function getUnreadMessageCount
 * @param {number} channelId - L'identifiant du canal de discussion.
 * @param {number} userId - L'identifiant de l'utilisateur.
 * @returns {Promise<number>} - Le nombre de messages non lus.
 */
const getUnreadMessageCount = async (channelId, userId) => {
    return await PrivateMessage.count({
        where: {
            channel_id: channelId,
            status: 'unread', 
            sender_id: {
                [Op.ne]: userId // Exclure les messages envoyés par l'utilisateur
            }
        }
    });
};


/**
 * Marque tous les messages non lus dans un canal comme lus pour un utilisateur.
 * 
 * @async
 * @function markMessagesAsRead
 * @param {number} channelId - L'identifiant du canal de discussion.
 * @param {number} userId - L'identifiant de l'utilisateur.
 * @returns {Promise<number[]>} - Le nombre de lignes affectées.
 */
const markMessagesAsRead = async (channelId, userId) => {
    return await PrivateMessage.update(
        { status: 'read' }, // Met à jour le statut à 'lu'
        {
            where: {
                channel_id: channelId,
                status: 'unread', // Cibler uniquement les messages non lus
                sender_id: {
                    [Op.ne]: userId // Exclure les messages envoyés par l'utilisateur
                }
            }
        }
    );
};


/**
 * Initialise la connexion Socket.IO et gère les événements de messagerie.
 *
 * @function initializeSocket
 * @param {Object} io - L'instance Socket.IO.
 */
const initializeSocket = (io) => {
    io.on('connection', (socket) => {
        console.log("Nouvelle connexion:", socket.id);
         /**
         * Gère l'événement lorsque l'utilisateur rejoint un canal.
         * 
         * @event joinChannel
         * @param {Object} data - Les données de l'événement.
         * @param {number} data.channelId - L'identifiant du canal.
         * @param {number} data.userId - L'identifiant de l'utilisateur.
         */
        socket.on('joinChannel', async (data) => {
            const { channelId, userId } = data; 
            
            // Marquer les messages non lus comme lus
            await markMessagesAsRead(channelId, userId);
            
            // Mettre à jour le compte des messages non lus après que l'utilisateur a rejoint
            const unreadCount = await getUnreadMessageCount(channelId, userId);
            io.to(channelId).emit('unreadCount', { count: unreadCount });
            
            socket.join(channelId);
        });

         /**
         * Gère l'envoi d'un message privé dans un canal.
         * 
         * @event privateMessage
         * @param {Object} data - Les données du message privé.
         * @param {number} data.senderId - L'identifiant de l'expéditeur.
         * @param {string} data.content - Le contenu du message.
         * @param {number} data.channelId - L'identifiant du canal.
         */
        socket.on('privateMessage', async ({ senderId, content, channelId }) => {
            try {
                // Créer le message dans la base de données
                const message = await PrivateMessage.create({
                    sender_id: senderId,
                    content,
                    channel_id: channelId,
                    status: 'unread',
                    createdAt: new Date()
                });

                const sender = await User.findByPk(senderId, { 
                    attributes: ['id', 'username', 'avatar'],
                    include: [
                        {
                            model: Inventory, // Inclure l'inventaire de l'utilisateur
                            where: { active: true }, // Filtrer uniquement les articles actifs
                            attributes: ['item_id', 'article_id', 'active'],
                            include: [
                                {
                                    model: Shop, // Inclure les détails de l'article
                                    attributes: ['title', 'type', 'content', 'amount']
                                }
                            ],
                            required: false // Assurer que même si pas d'inventaire, le message passe
                        }
                    ]
                });

                 // Envoyer le message au canal spécifique
                io.to(channelId).emit('newMessage', {
                    id: message.message_id,
                    content: message.content,
                    sender: sender,
                    createdAt: message.createdAt
                });
                 // Mettre à jour le compte des messages non lus pour tous les utilisateurs
                 const unreadCount = await getUnreadMessageCount(channelId, senderId);
                 io.to(channelId).emit('unreadCount', { count: unreadCount });
            } catch (error) {
                console.error('Error sending private message:', error.message);
            }
        });

         /**
         * Gère l'événement de départ de l'utilisateur d'un canal.
         * 
         * @event leaveChannel
         * @param {Object} data - Les données de l'événement.
         * @param {number} data.channelId - L'identifiant du canal quitté.
         */
        socket.on('leaveChannel', async ({channelId}) => {
            socket.leave(channelId);
        });

        /**
         * Gère la suppression d'un canal.
         * 
         * @event deleteChannel
         * @param {number} channelId - L'identifiant du canal à supprimer.
         */
        socket.on('deleteChannel', async (channelId) => {
            // Ici, tu devrais ajouter une vérification pour voir si l'utilisateur est le créateur
            try {
                await Channel.destroy({ where: { id: channelId } });
                io.to(channelId).emit('channelDeleted', channelId);
            } catch (error) {
                console.error('Error deleting channel:', error.message);
            }
        });

        /**
         * Gère la déconnexion de l'utilisateur du socket.
         * 
         * @event disconnect
         */
        socket.on('disconnect', () => {
            console.log(`Client disconnected: ${socket.id}`);
        });
    });
};

module.exports = initializeSocket;