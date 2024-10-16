const { Invoice, Shop, User } = require('../models');
const fs = require('fs');
const path = require('path');
const generateInvoice = require('../middlewares/generateInvoice');

/**
 * @module invoiceController
 * @description Ce module gère les opérations liées aux factures, y compris la lecture, la création, la mise à jour et la suppression des factures.
 */

/**
 * Lire toutes les factures du user connecté.
 *
 * @async
 * @function readAll
 * @param {Object} req - L'objet de requête contenant les détails de l'utilisateur connecté.
 * @param {Object} res - L'objet de réponse.
 * @returns {Object} 200 - Liste des factures de l'utilisateur connecté.
 * @throws {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la récupération des factures.
 */
exports.readAll = async (req, res) => {
    try {
        const invoices = await Invoice.findAll({ where: { user_id: req.auth.userId } });
        res.status(200).json(invoices);
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while fetching invoices.' });
    }
};

/**
 * Lire une facture par ID.
 *
 * @async
 * @function read
 * @param {Object} req - L'objet de requête contenant l'ID de la facture à lire.
 * @param {Object} res - L'objet de réponse.
 * @returns {Object} 200 - La facture demandée.
 * @throws {Object} 400 - Mauvaise requête si l'ID de la facture est manquant.
 * @throws {Object} 404 - Non trouvé si la facture n'existe pas ou si l'utilisateur n'est pas autorisé à la voir.
 * @throws {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la récupération de la facture.
 */
exports.read = async (req, res) => {
    try {
        const invoiceId = req.params.id;
        if (!invoiceId) {
            return res.status(400).json({ message: 'Invoice ID is required.' });
        }

        const invoice = await Invoice.findByPk(invoiceId);
        if (!invoice) {
            return res.status(404).json({ message: 'Invoice not found.' });
        }

        // Vérifiez si la facture appartient à l'utilisateur connecté
        if (invoice.user_id !== req.auth.userId) {
            return res.status(403).json({ message: 'You do not have permission to view this invoice.' });
        }

        const user = await User.findByPk(invoice.user_id);

        // Générer la facture PDF et obtenir le buffer
        const pdfData = await generateInvoice({
            id: invoice.id,
            username: user.username,
            email: user.email,
            createdAt: invoice.createdAt,
            content: invoice.content,
            amount: invoice.amount,
            quantity: invoice.quantity
        });

        const emailTemplatePath = path.join(__dirname, '../../templates/invoice-email.html');
        let htmlContent = fs.readFileSync(emailTemplatePath, 'utf8');

        // Envoyer l'e-mail avec le PDF en tant qu'attachement
        await req.mailer.sendEmail(
            user.email,
            `Facture N°${invoice.id}`,
            '',
            htmlContent,
            [{
                filename: `invoice_${invoice.id}.pdf`,
                content: pdfData,
                contentType: 'application/pdf',
            }]
        );

        res.status(200).json({ message: 'Invoice sent successfully via email.' });
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while fetching the invoice.' });
    }
};

/**
 * Créer une nouvelle facture (interdit aux utilisateurs ayant le rôle USER).
 *
 * @async
 * @function create
 * @param {Object} req - L'objet de requête contenant les détails de la facture à créer.
 * @param {Object} res - L'objet de réponse.
 * @returns {Object} 201 - La facture créée avec succès.
 * @throws {Object} 403 - Interdit si l'utilisateur n'est pas ADMIN ou SUPER_ADMIN.
 * @throws {Object} 400 - Mauvaise requête si l'ID de l'article ou l'ID de l'utilisateur est manquant.
 * @throws {Object} 404 - Non trouvé si l'article n'existe pas.
 * @throws {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la création de la facture.
 */
exports.create = async (req, res) => {
    try {
        // Vérifier que l'utilisateur est soit ADMIN, soit SUPER_ADMIN
        if (req.auth.userRole === 'USER') {
            return res.status(403).json({ message: 'You do not have permission to create an invoice.' });
        }

        const { article_id, user_id } = req.body;
        if (!article_id || !user_id) {
            return res.status(400).json({ message: 'Article ID and User ID are required.' });
        }

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

/**
 * Mettre à jour une facture (interdit aux utilisateurs ayant le rôle USER).
 *
 * @async
 * @function update
 * @param {Object} req - L'objet de requête contenant l'ID de la facture et les détails à mettre à jour.
 * @param {Object} res - L'objet de réponse.
 * @returns {Object} 200 - La facture mise à jour avec succès.
 * @throws {Object} 403 - Interdit si l'utilisateur n'est pas ADMIN ou SUPER_ADMIN.
 * @throws {Object} 400 - Mauvaise requête si l'ID de la facture est manquant.
 * @throws {Object} 404 - Non trouvé si la facture n'existe pas ou si l'article n'existe pas.
 * @throws {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la mise à jour de la facture.
 */
exports.update = async (req, res) => {
    try {
        if (req.auth.userRole === 'USER') {
            return res.status(403).json({ message: 'You do not have permission to update this invoice.' });
        }

        const invoiceId = req.params.id;
        if (!invoiceId) {
            return res.status(400).json({ message: 'Invoice ID is required.' });
        }

        const invoice = await Invoice.findByPk(invoiceId);
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

        if (quantity) {
            invoice.quantity = quantity;
        }

        await invoice.save();
        res.status(200).json({ message: 'Invoice updated successfully.', invoice });
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while updating the invoice.' });
    }
};

/**
 * Supprimer une facture (interdit aux utilisateurs ayant le rôle USER).
 *
 * @async
 * @function delete
 * @param {Object} req - L'objet de requête contenant l'ID de la facture à supprimer.
 * @param {Object} res - L'objet de réponse.
 * @returns {Object} 200 - Message de succès indiquant que la facture a été supprimée.
 * @throws {Object} 403 - Interdit si l'utilisateur n'est pas ADMIN ou SUPER_ADMIN.
 * @throws {Object} 400 - Mauvaise requête si l'ID de la facture est manquant.
 * @throws {Object} 404 - Non trouvé si la facture n'existe pas.
 * @throws {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la suppression de la facture.
 */
exports.delete = async (req, res) => {
    try {
        if (req.auth.userRole === 'USER') {
            return res.status(403).json({ message: 'You do not have permission to delete this invoice.' });
        }

        const invoiceId = req.params.id;
        if (!invoiceId) {
            return res.status(400).json({ message: 'Invoice ID is required.' });
        }

        const invoice = await Invoice.findByPk(invoiceId);
        if (!invoice) {
            return res.status(404).json({ message: 'Invoice not found.' });
        }

        await invoice.destroy();
        res.status(200).json({ message: 'Invoice deleted successfully.' });
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while deleting the invoice.' });
    }
};

/**
 * Lire toutes les factures (interdit aux utilisateurs ayant le rôle USER).
 *
 * @async
 * @function adminReadAll
 * @param {Object} req - L'objet de requête contenant les détails de l'utilisateur connecté.
 * @param {Object} res - L'objet de réponse.
 * @returns {Object} 200 - Liste de toutes les factures.
 * @throws {Object} 403 - Interdit si l'utilisateur n'est pas ADMIN ou SUPER_ADMIN.
 * @throws {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la récupération des factures.
 */
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
