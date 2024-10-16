const { PrivateMessage } = require('../models');

/**
 * @module privateMessageController
 * @description Ce module contient des fonctions pour gérer les messages privés, y compris la mise à jour et la suppression des messages.
 */

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

        await message.destroy();

        res.status(200).json({ message: "Message deleted successfully." });
    } catch (error) {
        res.status(500).json({ message: error.message || 'Une erreur est survenue lors de la suppression du message.' });
    }
};