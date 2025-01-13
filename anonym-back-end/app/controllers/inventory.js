const { Inventory, Shop, User } = require('../models');

/**
 * @module inventoryController
 * @description Ce module gère les opérations liées à l'inventaire des utilisateurs, y compris la lecture, la création, la mise à jour et la suppression des articles d'inventaire.
 */

/**
 * Lire un article spécifique dans l'inventaire d'un utilisateur.
 *
 * @async
 * @function read
 * @param {Object} req - L'objet de requête contenant l'ID de l'article à lire.
 * @param {Object} res - L'objet de réponse.
 * @returns {Object} 200 - L'article d'inventaire demandé.
 * @throws {Object} 400 - Mauvaise requête si l'ID de l'article est manquant.
 * @throws {Object} 404 - Non trouvé si l'article n'existe pas ou si l'utilisateur n'est pas autorisé à le voir.
 * @throws {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la récupération de l'article d'inventaire.
 */
exports.read = async (req, res) => {
    try {
        const itemId = req.params.item_id;

        if (!itemId) {
            return res.status(400).json({ message: 'Item ID is required.' });
        }

        const item = await Inventory.findByPk(itemId, {
            include: {
                model: Shop,
                attributes: ['article_id', 'title', 'type', 'content', 'amount']
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

/**
 * Lire tous les articles dans l'inventaire d'un utilisateur.
 *
 * @async
 * @function readAll
 * @param {Object} req - L'objet de requête contenant les détails de l'utilisateur connecté.
 * @param {Object} res - L'objet de réponse.
 * @returns {Object} 200 - Liste des articles d'inventaire de l'utilisateur.
 * @throws {Object} 400 - Mauvaise requête si l'ID de l'utilisateur est manquant.
 * @throws {Object} 404 - Non trouvé si aucun article d'inventaire n'est trouvé pour l'utilisateur.
 * @throws {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la récupération des articles d'inventaire.
 */
exports.readAll = async (req, res) => {
    try {
        const userId = req.auth.userId;

        if (!userId) {
            return res.status(400).json({ message: "User ID is required." });
        }

        const inventoryItems = await Inventory.findAll({
            where: { user_id: userId },
            include: [{ model: Shop }]
        });

        if (inventoryItems.length === 0) {
            return res.status(404).json({ message: 'Aucun article d\'inventaire trouvé' });
        }

        res.status(200).json(inventoryItems);
    } catch (error) {
        console.error("Error fetching inventory:", error);
        res.status(500).json({ message: error.message || 'An error occurred while fetching the inventory.' });
    }
};

/**
 * Mettre à jour le statut d'un article dans l'inventaire.
 *
 * @async
 * @function updateStatus
 * @param {Object} req - L'objet de requête contenant l'ID de l'article et le statut à mettre à jour.
 * @param {Object} res - L'objet de réponse.
 * @returns {Object} 200 - L'article d'inventaire mis à jour avec succès.
 * @throws {Object} 400 - Mauvaise requête si l'ID de l'article est manquant ou si le statut n'est pas un booléen.
 * @throws {Object} 404 - Non trouvé si l'article d'inventaire n'existe pas.
 * @throws {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la mise à jour du statut de l'article d'inventaire.
 */
exports.updateStatus = async (req, res) => {
    try {
        const itemId = req.params.item_id;
        const { active } = req.body;

        if (!itemId) {
            return res.status(400).json({ message: 'Item ID is required.' });
        }

        if (typeof active !== 'boolean') {
            return res.status(400).json({ message: "Active status must be a boolean." });
        }

        // Trouver l'inventaire par ID
        const inventory = await Inventory.findOne({
            where: { item_id: itemId },
            include: { model: Shop, attributes: ['type'] }
        });

        if (!inventory) {
            return res.status(404).json({ message: "Inventory not found" });
        }

        // Si l'article doit être activé
        if (active) {
            // Désactiver tous les autres articles du même type pour ce user_id
            const sameTypeInventories = await Inventory.findAll({
                where: {
                    user_id: inventory.user_id,
                },
                include: {
                    model: Shop,
                    where: { type: inventory.Shop.type }
                }
            });

            // Désactiver chaque item du même type
            await Promise.all(sameTypeInventories.map(async (inv) => {
                if (inv.item_id !== itemId) {
                    inv.active = false;
                    await inv.save();
                }
            }));
        }

        // Mettre à jour l'état actif de cet inventaire
        inventory.active = active;
        await inventory.save();

        res.status(200).json(inventory);
    } catch (error) {
        res.status(500).json({
            message: error.message || 'An error occurred while updating the inventory.'
        });
    }
};

/**
 * Admin - Lire tous les articles de tous les utilisateurs.
 *
 * @async
 * @function adminReadAll
 * @param {Object} req - L'objet de requête contenant les détails de l'utilisateur connecté.
 * @param {Object} res - L'objet de réponse.
 * @returns {Object} 200 - Liste de tous les articles d'inventaire.
 * @throws {Object} 403 - Interdit si l'utilisateur n'est pas ADMIN ou SUPER_ADMIN.
 * @throws {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la récupération des articles d'inventaire.
 */
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

/**
 * Admin - Créer un article dans l'inventaire.
 *
 * @async
 * @function create
 * @param {Object} req - L'objet de requête contenant les détails de l'article à créer.
 * @param {Object} res - L'objet de réponse.
 * @returns {Object} 201 - L'article d'inventaire créé avec succès.
 * @throws {Object} 403 - Interdit si l'utilisateur n'est pas ADMIN ou SUPER_ADMIN.
 * @throws {Object} 400 - Mauvaise requête si l'ID de l'utilisateur ou l'ID de l'article est manquant.
 * @throws {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la création de l'article d'inventaire.
 */
exports.create = async (req, res) => {
    try {
        if (req.auth.userRole === 'USER') {
            return res.status(403).json({ message: 'You do not have permission to create an inventory item.' });
        }

        const { user_id, article_id } = req.body;

        if (!user_id || !article_id) {
            return res.status(400).json({ message: 'User ID and Article ID are required.' });
        }

        const inventoryItem = await Inventory.create({
            user_id,
            article_id
        });

        res.status(201).json(inventoryItem);
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while creating the inventory item.' });
    }
};

/**
 * Admin - Mettre à jour un article dans l'inventaire.
 *
 * @async
 * @function update
 * @param {Object} req - L'objet de requête contenant l'ID de l'article et les détails à mettre à jour.
 * @param {Object} res - L'objet de réponse.
 * @returns {Object} 200 - L'article d'inventaire mis à jour avec succès.
 * @throws {Object} 403 - Interdit si l'utilisateur n'est pas ADMIN ou SUPER_ADMIN.
 * @throws {Object} 400 - Mauvaise requête si l'ID de l'article est manquant ou si l'ID de l'utilisateur ou l'ID de l'article sont manquants.
 * @throws {Object} 404 - Non trouvé si l'article d'inventaire n'existe pas.
 * @throws {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la mise à jour de l'article d'inventaire.
 */
exports.update = async (req, res) => {
    try {
        if (req.auth.userRole === 'USER') {
            return res.status(403).json({ message: 'You do not have permission to update an inventory item.' });
        }

        const itemId = req.params.item_id;
        const { user_id, article_id } = req.body;

        if (!itemId) {
            return res.status(400).json({ message: 'Item ID is required.' });
        }

        if (!user_id || !article_id) {
            return res.status(400).json({ message: 'User ID and Article ID are required.' });
        }

        const inventoryItem = await Inventory.findByPk(itemId);
        if (!inventoryItem) {
            return res.status(404).json({ message: 'Inventory item not found.' });
        }

        inventoryItem.user_id = user_id;
        inventoryItem.article_id = article_id;

        await inventoryItem.save();
        res.status(200).json(inventoryItem);
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while updating the inventory item.' });
    }
};

/**
 * Admin - Supprimer un article dans l'inventaire.
 *
 * @async
 * @function delete
 * @param {Object} req - L'objet de requête contenant l'ID de l'article à supprimer.
 * @param {Object} res - L'objet de réponse.
 * @returns {Object} 200 - Message de succès indiquant que l'article d'inventaire a été supprimé avec succès.
 * @throws {Object} 403 - Interdit si l'utilisateur n'est pas ADMIN ou SUPER_ADMIN.
 * @throws {Object} 400 - Mauvaise requête si l'ID de l'article est manquant.
 * @throws {Object} 404 - Non trouvé si l'article d'inventaire n'existe pas.
 * @throws {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la suppression de l'article d'inventaire.
 */
exports.delete = async (req, res) => {
    try {
        if (req.auth.userRole === 'USER') {
            return res.status(403).json({ message: 'You do not have permission to delete an inventory item.' });
        }

        const itemId = req.params.item_id;
        if (!itemId) {
            return res.status(400).json({ message: 'Item ID is required.' });
        }
        
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