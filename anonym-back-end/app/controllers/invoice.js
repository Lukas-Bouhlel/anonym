const { Invoice, Shop, User } = require('../models');

// Lire toutes les factures du user connecté
exports.readAll = async (req, res) => {
    try {
        const invoices = await Invoice.findAll({ where: { user_id: req.auth.userId } });
        console.log(invoices)
        res.status(200).json(invoices);
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while fetching invoices.' });
    }
};

// Lire une facture par ID
exports.read = async (req, res) => {
    try {
        const invoice = await Invoice.findByPk(req.params.id);

        // Vérifiez si la facture existe
        if (!invoice) {
            return res.status(404).json({ message: 'Invoice not found.' });
        }

        // Vérifiez si la facture appartient à l'utilisateur connecté
        if (invoice.user_id !== req.auth.userId) {
            return res.status(403).json({ message: 'You do not have permission to view this invoice.' });
        }

        res.status(200).json(invoice);
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while fetching the invoice.' });
    }
};

// Créer une nouvelle facture (interdit aux utilisateurs ayant le rôle USER)
exports.create = async (req, res) => {
    try {
        // Vérifier que l'utilisateur est soit ADMIN, soit SUPER_ADMIN
        if (req.auth.userRole === 'USER') {
            return res.status(403).json({ message: 'You do not have permission to create an invoice.' });
        }

        const { article_id, user_id } = req.body;

        const shopItem = await Shop.findByPk(article_id);
        if (!shopItem) {
            return res.status(404).json({ message: 'Item not found.' });
        }

        const newInvoice = await Invoice.create({
            user_id,
            article_id: shopItem.article_id,
            type: shopItem.type,
            amount: shopItem.amount,
            content: shopItem.title,
            quantity: 1
        });

        res.status(201).json({ message: 'Invoice created successfully.', invoice: newInvoice });
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while creating the invoice.' });
    }
};

// Mettre à jour une facture (interdit aux utilisateurs ayant le rôle USER)
exports.update = async (req, res) => {
    try {
        if (req.auth.userRole === 'USER') {
            return res.status(403).json({ message: 'You do not have permission to update this invoice.' });
        }

        const invoice = await Invoice.findByPk(req.params.id);
        if (!invoice) {
            return res.status(404).json({ message: 'Invoice not found.' });
        }

        const { article_id, user_id, quantity } = req.body;

        if (article_id) {
            const shopItem = await Shop.findByPk(article_id);
            if (!shopItem) {
                return res.status(404).json({ message: 'Item not found.' });
            }
            invoice.article_id = shopItem.article_id;
            invoice.type = shopItem.type;
            invoice.amount = shopItem.amount;
            invoice.content = shopItem.title;
        }

        if (user_id) {
            invoice.user_id = user_id;
        }

        invoice.quantity = quantity;

        await invoice.save();
        res.status(200).json({ message: 'Invoice updated successfully.', invoice });
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while updating the invoice.' });
    }
};

// Supprimer une facture (interdit aux utilisateurs ayant le rôle USER)
exports.delete = async (req, res) => {
    try {
        if (req.auth.userRole === 'USER') {
            return res.status(403).json({ message: 'You do not have permission to delete this invoice.' });
        }

        const invoice = await Invoice.findByPk(req.params.id);
        if (!invoice) {
            return res.status(404).json({ message: 'Invoice not found.' });
        }

        await invoice.destroy();
        res.status(200).json({ message: 'Invoice deleted successfully.' });
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while deleting the invoice.' });
    }
};

// Lire toutes les factures (interdit aux utilisateurs ayant le rôle USER)
exports.adminReadAll = async (req, res) => {
    try {
        if (req.auth.userRole === 'USER') {
            return res.status(403).json({ message: 'You do not have permission to view all invoices.' });
        }

        const invoices = await Invoice.findAll();
        res.status(200).json(invoices);
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while fetching invoices.' });
    }
};
