const { Invoice, Shop, Inventory } = require('../models');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const fs = require('fs');
const path = require('path');
const { sendServerError } = require('../utils/security');
const env = process.env.NODE_ENV || 'development';

const isProduction = env === 'production';

const getEnvVar = (baseName) => {
    const prodKey = `${baseName}_PROD`;
    return isProduction ? process.env[prodKey] || process.env[baseName] : process.env[baseName];
};

const normalizeBaseUrl = (value) => String(value || '').replace(/\/$/, '');
const appendPath = (baseUrl, pathSuffix) => `${normalizeBaseUrl(baseUrl)}${pathSuffix}`;
const isHttpLink = (url) => /^https?:\/\//i.test(String(url || '').trim());

const buildBridgeBaseUrl = (req) => {
    const protocol = req.protocol || 'http';
    const host = req.get?.('host');
    if (!host) return '';
    return `${protocol}://${host}`;
};

const getPaymentSuccessBaseUrl = (isMobile) => {
    const webDefault = isProduction ? process.env.ORIGIN_PROD : process.env.ORIGIN;
    const webBase = getEnvVar('PAYMENT_SUCCESS_WEB_URL') || webDefault;
    if (!isMobile) return webBase;

    return getEnvVar('PAYMENT_SUCCESS_MOBILE_URL') || getEnvVar('MOBILE_DEEP_LINK_BASE_URL') || 'anonym://';
};

const getPaymentCancelBaseUrl = (isMobile) => {
    const webDefault = isProduction ? process.env.ORIGIN_PROD : process.env.ORIGIN;
    const webBase = getEnvVar('PAYMENT_CANCEL_WEB_URL') || webDefault;
    if (!isMobile) return webBase;

    return getEnvVar('PAYMENT_CANCEL_MOBILE_URL') || getEnvVar('MOBILE_DEEP_LINK_BASE_URL') || 'anonym://';
};

/**
 * @module paymentController
 * @description Ce module gere les paiements via Stripe, y compris la creation de sessions de paiement et le traitement des confirmations de paiement.
 */

/**
 * Creer une session de paiement pour un article.
 *
 * @async
 * @function create
 * @param {Object} req - L'objet de requete contenant les details de l'article a acheter.
 * @param {Object} res - L'objet de reponse.
 * @throws {Object} 400 - Mauvaise requete si l'ID de l'article est manquant ou si l'utilisateur a deja achete cet article.
 * @throws {Object} 404 - Non trouve si l'article n'existe pas.
 * @returns {Object} 200 - URL de la session de paiement Stripe.
 * @returns {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la creation de la session de paiement.
 */
exports.create = async (req, res) => {
    try {
        const { article_id, platform } = req.body;
        const userId = req.auth.userId;
        const isMobile = String(platform || '').toLowerCase() === 'mobile';

        if (!article_id) {
            return res.status(400).json({ message: 'Article ID is required.' });
        }

        const successBaseUrl = getPaymentSuccessBaseUrl(isMobile);
        const cancelBaseUrl = getPaymentCancelBaseUrl(isMobile);
        const bridgeBaseUrl = buildBridgeBaseUrl(req);
        const requiresBridge = isMobile && (!isHttpLink(successBaseUrl) || !isHttpLink(cancelBaseUrl));

        if (!successBaseUrl) {
            return res.status(500).json({ message: 'Payment success URL is not configured.' });
        }

        if (!cancelBaseUrl) {
            return res.status(500).json({ message: 'Payment cancel URL is not configured.' });
        }

        if (requiresBridge && !bridgeBaseUrl) {
            return res.status(500).json({ message: 'Payment bridge URL is not configured.' });
        }

        // Trouver le produit
        const shopItem = await Shop.findOne({ where: { article_id: article_id } });
        if (!shopItem) {
            return res.status(404).json({ message: 'Item not found.' });
        }

        // Verifier que l'utilisateur n'a pas deja achete cet article
        const existingInvoice = await Invoice.findOne({
            where: {
                user_id: userId,
                article_id: article_id
            }
        });

        if (existingInvoice) {
            return res.status(400).json({ message: 'You have already purchased this item.' });
        }

        const successUrl = (isMobile && !isHttpLink(successBaseUrl))
            ? `${appendPath(bridgeBaseUrl, '/open-payment-success')}?session_id={CHECKOUT_SESSION_ID}`
            : `${appendPath(successBaseUrl, '/app/success')}?session_id={CHECKOUT_SESSION_ID}`;

        const cancelUrl = (isMobile && !isHttpLink(cancelBaseUrl))
            ? appendPath(bridgeBaseUrl, '/open-payment-cancel')
            : appendPath(cancelBaseUrl, '/app');

        // Creer une session de paiement Stripe
        const session = await stripe.checkout.sessions.create({
            payment_method_types: ['card'],
            line_items: [{
                price_data: {
                    currency: 'eur',
                    product_data: {
                        name: shopItem.title,
                        images: [shopItem.content]
                    },
                    unit_amount: shopItem.amount * 100,
                },
                quantity: 1,
            }],
            mode: 'payment',
            success_url: successUrl,
            cancel_url: cancelUrl,
            metadata: {
                userId: userId,
                articleId: article_id
            },
        });

        res.status(200).json({ url: session.url });
    } catch (error) {
        return sendServerError(res, error, 'An error occurred during the payment process.', {
            scope: 'payment.create',
            userId: req.auth?.userId,
            articleId: req.body?.article_id
        });
    }
};

/**
 * Traiter la confirmation d'un paiement reussi.
 *
 * @async
 * @function success
 * @param {Object} req - L'objet de requete contenant l'ID de la session de paiement.
 * @param {Object} res - L'objet de reponse.
 * @throws {Object} 400 - Mauvaise requete si l'ID de session est manquant ou si le paiement n'est pas complet.
 * @throws {Object} 404 - Non trouve si l'article ou la facture existe deja.
 * @returns {Object} 200 - Message de succes avec les details de la facture creee.
 * @returns {Object} 500 - Erreur interne du serveur si une erreur se produit lors du traitement de la confirmation du paiement.
 */
exports.success = async (req, res) => {
    try {
        const session_id = req.query.session_id;

        if (!session_id) {
            return res.status(400).json({ message: 'Session ID is required.' });
        }

        const session = await stripe.checkout.sessions.retrieve(session_id);

        if (session.payment_status === 'paid') {
            const userId = session.metadata.userId;
            const articleId = session.metadata.articleId;
            const userEmail = session.customer_details.email;

            const shopItem = await Shop.findOne({ where: { article_id: articleId } });

            const existingInvoice = await Invoice.findOne({
                where: {
                    user_id: userId,
                    article_id: articleId
                }
            });

            if (existingInvoice) {
                return res.status(400).json({ message: 'You have already purchased this item.' });
            }

            const newInvoice = await Invoice.create({
                user_id: userId,
                article_id: shopItem.article_id,
                type: shopItem.type,
                amount: shopItem.amount,
                content: shopItem.title,
                quantity: 1
            });

            await Inventory.create({
                user_id: userId,
                article_id: articleId
            });

            const emailTemplatePath = path.join(__dirname, '../../templates/confirm-payment-email.html');
            let htmlContent = fs.readFileSync(emailTemplatePath, 'utf8');

            const formattedDate = new Date(shopItem.createdAt).toLocaleDateString('fr-FR', {
                day: '2-digit',
                month: '2-digit',
                year: 'numeric'
            });

            htmlContent = htmlContent.replace(/Emblème de feu|Embleme de feu/u, `${shopItem.title}`);
            htmlContent = htmlContent.replace(/1€|1EUR/u, `${shopItem.amount}€`);
            htmlContent = htmlContent.replace('Le 19/06/1998', `Le ${formattedDate}`);

            await req.mailer.sendEmail(
                userEmail,
                'Merci pour votre achat !',
                '',
                htmlContent
            );

            return res.status(200).json({ message: 'Payment successful, invoice created.', invoice: newInvoice });
        }

        return res.status(400).json({ message: 'Payment not completed.' });
    } catch (error) {
        return sendServerError(res, error, 'Error confirming payment', {
            scope: 'payment.success',
            sessionId: req.query?.session_id
        });
    }
};
