const { Invoice, Shop, Inventory } = require('../models');

exports.create = async (req, res) => {
    try {
        const { article_id } = req.body; // ID du produit acheté
        const userId = req.auth.userId;

        // Trouver le produit
        const shopItem = await Shop.findOne({ where: { article_id: article_id } });
        if (!shopItem) {
            return res.status(404).json({ message: "Item not found." });
        }

        // Vérifier que l'utilisateur n'a pas déjà acheté cet article
        const existingInvoice = await Invoice.findOne({
            where: {
                user_id: userId,
                article_id: article_id
            }
        });

        if (existingInvoice) {
            return res.status(400).json({ message: "You have already purchased this item." });
        }

        // Créer une nouvelle facture
        const newInvoice = await Invoice.create({
            user_id: userId,
            article_id: shopItem.article_id,
            type: shopItem.type,
            amount: shopItem.amount,
            content: shopItem.title,
            quantity: 1
        });

        // Ici, vous ajouteriez également la logique de paiement (via Stripe, PayPal, etc.)
        // Simuler le succès du paiement pour l'exemple

        // Ajouter l'article à l'inventaire de l'utilisateur
        await Inventory.create({
            user_id: userId,
            article_id: article_id
        });

        res.status(201).json({ message: "Payment successful. Invoice created.", invoice: newInvoice });
    } catch (error) {
        res.status(500).json({
            message: error.message || 'An error occurred during the payment process.'
        });
    }
};