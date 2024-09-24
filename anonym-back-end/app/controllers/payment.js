const { Invoice, Shop, Inventory } = require('../models');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const fs = require('fs');
const path = require('path');

exports.create = async (req, res) => {
    try {
        const { article_id } = req.body; // ID du produit acheté
        const userId = req.auth.userId;

        if (!article_id) {
            return res.status(400).json({ message: "Article ID is required." });
        }

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

        // Créer une session de paiement Stripe
        const session = await stripe.checkout.sessions.create({
            payment_method_types: ['card'],
            line_items: [{
                price_data: {
                    currency: 'eur',
                    product_data: {
                        name: shopItem.title,
                        images: [shopItem.content]
                    },
                    unit_amount: shopItem.amount * 100, // Montant en centimes
                },
                quantity: 1,
            }],
            mode: 'payment',
            success_url: `${process.env.ORIGIN}/app/success?session_id={CHECKOUT_SESSION_ID}`,
            cancel_url: `${process.env.ORIGIN}/app`,
            metadata: {
                userId: userId, // Inclure le userId
                articleId: article_id // Inclure l'article ID
            },
        });

         // Renvoyer l'URL de la session de paiement
         res.status(200).json({ url: session.url });
    } catch (error) {
        res.status(500).json({
            message: error.message || 'An error occurred during the payment process.'
        });
    }
};
// Route de succès après le paiement
exports.success = async (req, res) => {
    try {
        const session_id = req.query.session_id;  // Récupérer session_id depuis la requête

        if (!session_id) {
            return res.status(400).json({ message: 'Session ID is required.' });
        }
        // Récupérer la session de paiement via l'ID
        const session = await stripe.checkout.sessions.retrieve(session_id);

        // Vérifier si le paiement est bien 'paid'
        if (session.payment_status === 'paid') {
            const userId = session.metadata.userId; // Récupérer userId des métadonnées
            const articleId = session.metadata.articleId;
            const userEmail = session.customer_details.email;

            // Récupérer le shopItem pour créer l'invoice
            const shopItem = await Shop.findOne({ where: { article_id: articleId } });

            // Vérifier que l'utilisateur n'a pas déjà acheté cet article
            const existingInvoice = await Invoice.findOne({
                where: {
                    user_id: userId,
                    article_id: articleId
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

            // Ajouter l'article à l'inventaire de l'utilisateur
            await Inventory.create({
                user_id: userId,
                article_id: articleId
            });

            // Lire le fichier HTML pour l'e-mail
            const emailTemplatePath = path.join(__dirname, '../../templates/confirm-payment-email.html');
            let htmlContent = fs.readFileSync(emailTemplatePath, 'utf8');

            // Formater la date de création dans le format DD/MM/YYYY
            const formattedDate = new Date(shopItem.createdAt).toLocaleDateString('fr-FR', {
                day: '2-digit',
                month: '2-digit',
                year: 'numeric'
            });

            // Remplacer le nom de l'utilisateur dans le contenu HTML
            htmlContent = htmlContent.replace('Emblème de feu', `${shopItem.title}`);
            htmlContent = htmlContent.replace('1€', `${shopItem.amount}€`);
            htmlContent = htmlContent.replace('Le 19/06/1998', `Le ${formattedDate}`);

            // Envoyer l'e-mail de confirmation avec le contenu HTML
            await req.mailer.sendEmail(
                userEmail,                                // Destinataire
                'Merci pour votre achat !', // Sujet
                '',                                       // Contenu texte (vide)
                htmlContent                                // Contenu HTML
            );

            return res.status(200).json({ message: 'Payment successful, invoice created.', invoice: newInvoice });
        } else {
            return res.status(400).json({ message: 'Payment not completed.' });
        }
    } catch (error) {
        res.status(500).json({ message: 'Error confirming payment', error: error.message });
    }
};