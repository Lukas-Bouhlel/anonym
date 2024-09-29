const { PrivateMessage, User } = require('../models');

// Mettre à jour un message
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

// Supprimer un message
exports.delete = async (req, res) => {
    try {
        const { message_id } = req.params;

        const message = await PrivateMessage.findOne({ where: { message_id, sender_id: req.auth.userId } });

        if (!message) {
            return res.status(404).json({ message: "Message not found or you're not the sender." });
        }

        await message.destroy();

        res.status(200).json({ message: "Message deleted successfully." });
    } catch (error) {
        res.status(500).json({ message: error.message || 'Une erreur est survenue lors de la suppression du message.' });
    }
};

// Lire les messages entre deux utilisateurs
exports.read = async (req, res) => {
    try {
        const { channel_id } = req.params;

        const messages = await Message.findAll({
            where: { channel_id },
            order: [['createdAt', 'ASC']], // Trier les messages par date de création
            include: [{
                model: User, // Associe les messages aux utilisateurs pour récupérer leurs infos (ex: username, avatar)
                attributes: ['username', 'avatar']
            }]
        });

        res.status(200).json(messages);
    } catch (error) {
        res.status(500).json({ message: error.message || 'Une erreur est survenue lors de la récupération des messages.' });
    }
};