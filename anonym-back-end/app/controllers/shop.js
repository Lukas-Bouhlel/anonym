const { Shop } = require('../models');

// Lister tous les articles
exports.readAll = async (req, res) => {
    try {
        const shop = await Shop.findAll();
        res.status(200).json(shop);
    } catch (error) {
        res.status(500).json({ message: error.message || "An error occurred while retrieving the shop." });
    }
};

// Lire un article spécifique par ID
exports.read = async (req, res) => {
    try {
        const shop = await Shop.findByPk(req.params.id);
        if (!shop) {
            return res.status(404).json({ message: "Shop item not found." });
        }
        res.status(200).json(shop);
    } catch (error) {
        res.status(500).json({ message: error.message || "An error occurred while retrieving the shop item." });
    }
};

// Créer un nouvel article
exports.create = async (req, res) => {
    try {
        const { amount, timestamp, title, type, content } = req.body;

        // Vérifier que l'utilisateur est soit ADMIN, soit SUPER_ADMIN
        if (req.auth.userRole === 'USER') {
            return res.status(403).json({ message: "You do not have permission to create a article." });
        }
    
        // Validation pour les champs requis
        if (!amount || !title || !type || !content) {
            return res.status(400).json({ message: "Amount, title, type, and content are required." });
        }

        const shop = await Shop.create({ amount, timestamp, title, type, content });
        res.status(201).json(shop);
    } catch (error) {
        res.status(500).json({ message: error.message || "An error occurred while creating the shop item." });
    }
};

// Mettre à jour un article spécifique par ID
exports.update = async (req, res) => {
    try {
        // Vérifier que l'utilisateur est soit ADMIN, soit SUPER_ADMIN
        if (req.auth.userRole === 'USER') {
            return res.status(403).json({ message: "You do not have permission to create a article." });
        }

        const shop = await Shop.findByPk(req.params.id);

        if (!shop) {
            return res.status(404).json({ message: "Shop item not found." });
        }

        const { amount, timestamp, title, type, content } = req.body;

        // Mise à jour des champs
        if (amount) shop.amount = amount;
        if (timestamp) shop.timestamp = timestamp;
        if (title) shop.title = title;
        if (type) shop.type = type;
        if (content) shop.content = content;

        await shop.save();
        res.status(200).json(shop);
    } catch (error) {
        res.status(500).json({ message: error.message || "An error occurred while updating the shop item." });
    }
};

// Supprimer un article spécifique par ID
exports.delete = async (req, res) => {
    try {
        // Vérifier que l'utilisateur est soit ADMIN, soit SUPER_ADMIN
        if (req.auth.userRole === 'USER') {
            return res.status(403).json({ message: "You do not have permission to create a article." });
        }

        const shop = await Shop.findByPk(req.params.id);
        if (!shop) {
            return res.status(404).json({ message: "Shop item not found." });
        }

        await shop.destroy();
        res.status(200).json({ message: "Shop item successfully deleted." });
    } catch (error) {
        res.status(500).json({ message: error.message || "An error occurred while deleting the shop item." });
    }
};

// Gérer le paiement d'un article spécifique par ID (exemple basique)
exports.payment = async (req, res) => {
    try {
        const shop = await Shop.findByPk(req.params.id);
        if (!shop) {
            return res.status(404).json({ message: "Shop item not found." });
        }

        // Logique de paiement simplifiée (à adapter selon vos besoins)
        // Ici, vous pourriez appeler un service de paiement, vérifier l'état, etc.
        res.status(200).json({ message: `Payment processed for shop item ${shop.id}.` });
    } catch (error) {
        res.status(500).json({ message: error.message || "An error occurred while processing the payment." });
    }
};