const { Inventory, Shop, User } = require('../models');

// Lire un article spécifique dans l'inventaire d'un utilisateur
exports.read = async (req, res) => {
    try {
        const item = await Inventory.findByPk(req.params.item_id, {
            include: {
                model: Shop, // Inclure les détails de l'article depuis le modèle Shop
                attributes: ['article_id', 'title', 'type', 'content', 'amount'] // Sélectionner les attributs que vous voulez afficher
            }
        });

        // Vérifiez si la facture existe
        if (!item) {
            return res.status(404).json({ message: 'item not found.' });
        }

        // Vérifiez si la facture appartient à l'utilisateur connecté
        if (item.user_id !== req.auth.userId) {
            return res.status(403).json({ message: 'You do not have permission to view this item.' });
        }

        res.status(200).json(item.Shop);
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while fetching the inventory item.' });
    }
};

// Lire tous les articles dans l'inventaire d'un utilisateur
exports.readAll = async (req, res) => {
    try {
        const userId = req.auth.userId;

        const inventoryItems = await Inventory.findAll({
            where: { user_id: userId },
            include: [{ model: Shop }]
        });

        res.status(200).json(inventoryItems);
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while fetching the inventory.' });
    }
};

// Admin - Lire tous les articles de tous les utilisateurs
exports.adminReadAll = async (req, res) => {
    try {
        if (req.auth.userRole === 'USER') {
            return res.status(403).json({ message: 'You do not have permission to access this resource.' });
        }

        const inventoryItems = await Inventory.findAll({
            include: [{ model: Shop }, { model: User }]
        });

        res.status(200).json(inventoryItems);
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while fetching the inventory.' });
    }
};

// Admin - Créer un article dans l'inventaire
exports.create = async (req, res) => {
    try {
        if (req.auth.userRole === 'USER') {
            return res.status(403).json({ message: 'You do not have permission to create an inventory item.' });
        }

        const { user_id, article_id } = req.body;

        const inventoryItem = await Inventory.create({
            user_id,
            article_id
        });

        res.status(201).json(inventoryItem);
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while creating the inventory item.' });
    }
};

// Admin - Mettre à jour un article dans l'inventaire
exports.update = async (req, res) => {
    try {
        if (req.auth.userRole === 'USER') {
            return res.status(403).json({ message: 'You do not have permission to update an inventory item.' });
        }

        const itemId = req.params.item_id;
        const { user_id, article_id } = req.body;

        const inventoryItem = await Inventory.findByPk(itemId);
        if (!inventoryItem) {
            return res.status(404).json({ message: 'Inventory item not found.' });
        }

        inventoryItem.user_id = user_id || inventoryItem.user_id;
        inventoryItem.article_id = article_id || inventoryItem.article_id;

        await inventoryItem.save();
        res.status(200).json(inventoryItem);
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while updating the inventory item.' });
    }
};

// Admin - Supprimer un article dans l'inventaire
exports.delete = async (req, res) => {
    try {
        if (req.auth.userRole === 'USER') {
            return res.status(403).json({ message: 'You do not have permission to delete an inventory item.' });
        }

        const itemId = req.params.item_id;

        const inventoryItem = await Inventory.findByPk(itemId);
        if (!inventoryItem) {
            return res.status(404).json({ message: 'Inventory item not found.' });
        }

        await inventoryItem.destroy();
        res.status(200).json({ message: 'Inventory item deleted successfully.' });
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while deleting the inventory item.' });
    }
};