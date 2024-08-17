const { PrivateMessage, User } = require('../models');
const { Op } = require('sequelize');

// Créer un message
exports.create = async (req, res) => {
    try {
        const { receiver_id, content } = req.body;
        const sender_id = req.auth.userId; // L'ID de l'utilisateur connecté

        const message = await PrivateMessage.create({ sender_id, receiver_id, content });

        res.status(201).json(message);
    } catch (error) {
        res.status(500).json({ message: error.message || 'Une erreur est survenue lors de la création du message.' });
    }
};

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
        const { userId } = req.auth; // L'ID de l'utilisateur connecté
        const otherUserId = req.params.otherUserId; // L'ID de l'autre utilisateur

        // Vérifier si l'otherUserId est défini
        if (!otherUserId) {
            return res.status(400).json({ message: "Other user ID is required." });
        }

        const messages = await PrivateMessage.findAll({
            where: {
                [Op.or]: [
                    { sender_id: userId, receiver_id: otherUserId },
                    { sender_id: otherUserId, receiver_id: userId }
                ]
            },
            include: [
                { model: User, as: 'Sender', attributes: ['id', 'username'] },
                { model: User, as: 'Receiver', attributes: ['id', 'username'] }
            ],
            order: [['createdAt', 'ASC']] // Trier par ordre chronologique
        });

        if (!messages.length) {
            return res.status(404).json({ message: "No messages found between you and this user." });
        }

        res.status(200).json(messages);
    } catch (error) {
        res.status(500).json({ message: error.message || 'Une erreur est survenue lors de la récupération des messages.' });
    }
};