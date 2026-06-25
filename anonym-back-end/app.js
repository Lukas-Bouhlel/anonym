const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const rateLimit = require('express-rate-limit');
const slowDown = require('express-slow-down');
const multer = require('multer');
const app = express();
const helmet = require('helmet');
const router = require("./app/routes/index.js");
const db = require("./app/models/index.js");
const path = require('path');
const createMailer = require('./app/utils/mailer.js');
const { ensureCsrfCookie } = require('./app/middlewares/csrf');
const {
    healthHandler,
    httpLogger,
    metricsHandler,
    metricsMiddleware
} = require('./app/utils/observability');
const env = process.env.NODE_ENV || 'development';

const configuredOrigin =
    env === 'production'
        ? process.env.ORIGIN_PROD
        : env === 'preprod'
            ? process.env.ORIGIN_PREPROD
            : process.env.ORIGIN;

const isAllowedDevOrigin = (origin) => {
    if (!origin) return true;
    try {
        const { hostname } = new URL(origin);
        return hostname === 'localhost' || hostname === '127.0.0.1';
    } catch {
        return false;
    }
};

const isAllowedOrigin = (origin) => {
    if (!origin) return true;
    if (origin === configuredOrigin) return true;

    if (env === 'development') {
        return isAllowedDevOrigin(origin);
    }

    return false;
};

const getRuntimeEnvVar = (baseName) => {
    if (env === 'production') {
        return process.env[`${baseName}_PROD`] || process.env[baseName];
    }
    if (env === 'preprod') {
        return process.env[`${baseName}_PREPROD`] || process.env[baseName];
    }
    return process.env[baseName];
};

const buildResetPasswordLink = (baseUrl, token) => {
    if (typeof baseUrl !== 'string') return '';
    const trimmedBaseUrl = baseUrl.trim();
    if (!trimmedBaseUrl) return '';

    const encodedToken = encodeURIComponent(token);

    if (trimmedBaseUrl.includes('{token}')) {
        return trimmedBaseUrl.replace('{token}', encodedToken);
    }

    const withoutTrailingSlash = trimmedBaseUrl.replace(/\/+$/, '');
    const hasResetPath = /\/reset\/?(\?|$)/i.test(withoutTrailingSlash);
    const urlWithResetPath = hasResetPath ? withoutTrailingSlash : `${withoutTrailingSlash}/reset/`;
    const separator = urlWithResetPath.includes('?') ? '&' : '?';

    return `${urlWithResetPath}${separator}token=${encodedToken}`;
};

const getResetPasswordWebBaseUrl = () => {
    return getRuntimeEnvVar('RESET_PASSWORD_WEB_URL')
        || getRuntimeEnvVar('RESET_PASSWORD_URL')
        || getRuntimeEnvVar('ORIGIN');
};

const getResetPasswordMobileBaseUrl = () => getRuntimeEnvVar('RESET_PASSWORD_MOBILE_URL');

const getPaymentSuccessWebBaseUrl = () => {
    return getRuntimeEnvVar('PAYMENT_SUCCESS_WEB_URL')
        || getRuntimeEnvVar('ORIGIN');
};

const getPaymentSuccessMobileBaseUrl = () => getRuntimeEnvVar('PAYMENT_SUCCESS_MOBILE_URL');

const getPaymentCancelWebBaseUrl = () => {
    return getRuntimeEnvVar('PAYMENT_CANCEL_WEB_URL')
        || getRuntimeEnvVar('ORIGIN');
};

const getPaymentCancelMobileBaseUrl = () => getRuntimeEnvVar('PAYMENT_CANCEL_MOBILE_URL');

const appendDeepLinkPath = (baseUrl, pathSuffix) => {
    if (typeof baseUrl !== 'string') return '';
    const trimmed = baseUrl.trim();
    if (!trimmed) return '';

    const cleanPath = String(pathSuffix || '').replace(/^\/+/, '');

    if (trimmed.endsWith(':///')) return `${trimmed}${cleanPath}`;
    if (trimmed.endsWith('://')) return `${trimmed}/${cleanPath}`;
    if (trimmed.endsWith('/')) return `${trimmed}${cleanPath}`;
    return `${trimmed}/${cleanPath}`;
};

const withQuery = (url, query = {}) => {
    const entries = Object.entries(query).filter(([, value]) => {
        if (value === null || value === undefined) return false;
        return String(value).trim().length > 0;
    });
    if (!url || entries.length === 0) return url;
    const search = new URLSearchParams(entries.map(([key, value]) => [key, String(value)])).toString();
    if (!search) return url;
    const separator = url.includes('?') ? '&' : '?';
    return `${url}${separator}${search}`;
};

const escapeHtml = (value) => String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');

/**
 * Connexion à la base de données avec Sequelize.
 * @function authenticate
 * @memberof sequelize
 * @returns {Promise} - Résolution de la promesse si la connexion à la base de données est réussie.
 */
if (env !== 'test') {
    db.sequelize
        .authenticate()
        .then(() => console.log("Database connected..."))
        .catch((err) => console.log(err));
}

const mailerConfig = {
    service: 'gmail',
    auth: {
        user: process.env.MAIL_USER,
        pass: process.env.MAIL_PASS,
    },
};

/**
 * Configuration du mailer via le module personnalisé.
 * @type {MailerConfig}
 */
const mailer = createMailer(mailerConfig); // Instanciation de mailer

/**
 * Instance du service de mail pour l'envoi d'e-mails.
 * Ajoute l'instance du mailer à chaque requête HTTP.
 * @function createMailer
 * @param {MailerConfig} mailerConfig - La configuration du service de messagerie.
 * @returns {Object} - Instance du mailer.
 */
app.use((req, res, next) => {
    req.mailer = mailer; // Ajouter l'instance du mailer à l'objet req
    next();
});

app.use(express.json());
app.use(httpLogger);
app.use(metricsMiddleware);

/**
 * Limite le nombre de requêtes par IP sur une fenêtre de temps.
 * @function rateLimit
 * @param {Object} options - Options de limitation de requêtes.
 * @param {number} options.windowMs - Fenêtre de temps en millisecondes.
 * @param {number} options.max - Nombre maximal de requêtes autorisées par fenêtre de temps.
 * @param {Object} options.message - Message renvoyé lorsque la limite est dépassée.
 * @returns {Function} Middleware pour limiter les requêtes.
 */
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: Number(process.env.RATE_LIMIT_WRITE_MAX || 1200),
    validate: { trustProxy: false },
    standardHeaders: true,
    legacyHeaders: false,
    skip: (req) => ['GET', 'HEAD', 'OPTIONS'].includes((req.method || '').toUpperCase()),
    message: {
        message: "Trop de requetes d'ecriture effectuees depuis cette adresse IP, veuillez reessayer plus tard.",
    },
});

app.use(limiter);

/**
 * Ralentit les requêtes après un certain nombre d'appels.
 * @function slowDown
 * @param {Object} options - Options de ralentissement.
 * @param {number} options.windowMs - Période sur laquelle le ralentissement est appliqué.
 * @param {number} options.delayAfter - Nombre de requêtes avant d'ajouter un délai.
 * @param {Function} options.delayMs - Délai ajouté à chaque requête après le seuil.
 * @returns {Function} Middleware pour ralentir les requêtes.
 */
const speedLimiter = slowDown({
    windowMs: 15 * 60 * 1000, // Période de 15 minutes
    delayAfter: Number(process.env.RATE_LIMIT_WRITE_DELAY_AFTER || 250),
    delayMs: () => Number(process.env.RATE_LIMIT_WRITE_DELAY_MS || 150),
    skip: (req) => ['GET', 'HEAD', 'OPTIONS'].includes((req.method || '').toUpperCase()),
    validate: { trustProxy: false }
});

app.use(speedLimiter);

app.use(helmet());

/**
 * Middleware Helmet pour sécuriser l'application via des headers HTTP.
 * Inclut une configuration stricte de la politique de sécurité du contenu (CSP).
 * @function helmet
 * @param {Object} options - Options de configuration de Helmet.
 * @param {Object} options.contentSecurityPolicy - Définit les directives CSP.
 * @param {Object} options.crossOriginEmbedderPolicy - Politique pour les ressources embarquées.
 * @param {Object} options.crossOriginResourcePolicy - Politique pour les ressources cross-origin.
 * @returns {Function} Middleware pour renforcer la sécurité.
 */
app.use(helmet({
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],  // Autoriser les ressources provenant de la même origine
            imgSrc: ["'self'", env === 'production' ? process.env.ORIGIN_PROD : env === 'preprod' ? process.env.ORIGIN_PREPROD : process.env.ORIGIN, "data:"],  // Permettre le chargement d'images depuis localhost:5000 et les données inline (pour les avatars par ex)
            scriptSrc: ["'self'", env === 'production' ? process.env.ORIGIN_PROD : env === 'preprod' ? process.env.ORIGIN_PREPROD : process.env.ORIGIN],  // Permettre les scripts depuis localhost:5000
            styleSrc: ["'self'", "'unsafe-inline'"],  // Permet les styles inline (facultatif)
            fontSrc: ["'self'", env === 'production' ? process.env.ORIGIN_PROD : env === 'preprod' ? process.env.ORIGIN_PREPROD : process.env.ORIGIN],  // Permettre les polices de caractères depuis localhost:5000
            connectSrc: ["'self'", env === 'production' ? process.env.ORIGIN_PROD : env === 'preprod' ? process.env.ORIGIN_PREPROD : process.env.ORIGIN], // Autoriser les connexions à localhost:5000 (pour les API, WebSocket, etc.)
            objectSrc: ["'none'"], // Bloquer les objets embarqués, par exemple Flash (sécurité)
            frameSrc: ["'none'"],  // Bloquer les iframes externes (sécurité)
        },
    },
    crossOriginEmbedderPolicy: false,  // Désactiver si vous avez des vidéos ou images cross-origin
    crossOriginResourcePolicy: { policy: "cross-origin" }, // Autoriser le chargement des ressources cross-origin
}));

/**
 * Configuration de CORS pour l'application.
 * @function cors
 * @param {Object} options - Options de configuration CORS.
 * @param {string} options.origin - Origine autorisée pour les requêtes.
 * @param {boolean} options.credentials - Autorise l'envoi de cookies avec les requêtes CORS.
 * @param {Array<string>} options.methods - Méthodes HTTP autorisées.
 * @param {Array<string>} options.allowedHeaders - Headers autorisés dans les requêtes.
 * @returns {Function} Middleware pour gérer les requêtes cross-origin.
 */
app.use(cors({
    origin: (origin, callback) => {
        if (isAllowedOrigin(origin)) {
            return callback(null, true);
        }

        return callback(new Error(`Origin not allowed by CORS: ${origin}`));
    },
    credentials: true,  // Permet les cookies
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-CSRF-Token']
}));

app.use(cookieParser());

/**
 * Sert les fichiers statiques dans le dossier 'uploads'.
 * @function express.static
 * @param {string} path - Chemin vers le dossier des fichiers statiques.
 * @returns {Function} Middleware pour servir les fichiers statiques.
 */
app.use("/uploads", express.static(path.join(__dirname, "uploads")));
app.set('trust proxy', true);

app.get('/health', healthHandler);
app.get('/status', healthHandler);
app.get('/api/health', healthHandler);
app.get('/metrics', metricsHandler);

app.get('/open-reset-password', (req, res) => {
    const token = typeof req.query?.token === 'string' ? req.query.token.trim() : '';
    if (!token) {
        return res.status(400).type('text/plain').send('Token de reinitialisation manquant.');
    }

    const webResetLink = buildResetPasswordLink(getResetPasswordWebBaseUrl(), token);
    const mobileResetLink = buildResetPasswordLink(getResetPasswordMobileBaseUrl(), token);
    const openLink = mobileResetLink || webResetLink;
    const fallbackLink = webResetLink || '/';

    if (!openLink) {
        return res.status(500).type('text/plain').send("Aucun lien de reinitialisation configure.");
    }

    const safeOpenLink = escapeHtml(openLink);
    const safeFallbackLink = escapeHtml(fallbackLink);

    return res.status(200).type('html').send(`<!doctype html>
<html lang="fr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Ouverture Anonym</title>
  <meta http-equiv="refresh" content="0;url=${safeOpenLink}">
  <style>
    body { font-family: Arial, sans-serif; margin: 0; background: #121212; color: #f4f4f4; }
    .wrap { max-width: 460px; margin: 10vh auto; padding: 24px; text-align: center; }
    .btn { display: inline-block; margin-top: 16px; padding: 12px 16px; border-radius: 8px; background: #ffffff; color: #121212; font-weight: 700; text-decoration: none; }
    .muted { opacity: .8; font-size: 14px; margin-top: 12px; }
    a.fallback { color: #c4d4ff; word-break: break-all; }
  </style>
</head>
<body>
  <div class="wrap">
    <h1>Ouverture de l'application...</h1>
    <p>Si l'application ne s'ouvre pas automatiquement, utilise le bouton ci-dessous.</p>
    <a class="btn" href="${safeOpenLink}">Ouvrir Anonym</a>
    <p class="muted">Lien web de secours :</p>
    <a class="fallback" href="${safeFallbackLink}">${safeFallbackLink}</a>
  </div>
</body>
</html>`);
});

app.get('/open-payment-success', (req, res) => {
    const sessionId = typeof req.query?.session_id === 'string' ? req.query.session_id.trim() : '';
    const webSuccessLink = withQuery(
        appendDeepLinkPath(getPaymentSuccessWebBaseUrl(), '/app/success'),
        { session_id: sessionId }
    );
    const mobileSuccessLink = withQuery(
        appendDeepLinkPath(getPaymentSuccessMobileBaseUrl(), '/app/success'),
        { session_id: sessionId }
    );
    const openLink = mobileSuccessLink || webSuccessLink;
    const fallbackLink = webSuccessLink || '/';

    if (!openLink) {
        return res.status(500).type('text/plain').send("Aucun lien de retour paiement configure.");
    }

    const safeOpenLink = escapeHtml(openLink);
    const safeFallbackLink = escapeHtml(fallbackLink);

    return res.status(200).type('html').send(`<!doctype html>
<html lang="fr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Retour vers Anonym</title>
  <meta http-equiv="refresh" content="0;url=${safeOpenLink}">
  <style>
    body { font-family: Arial, sans-serif; margin: 0; background: #121212; color: #f4f4f4; }
    .wrap { max-width: 460px; margin: 10vh auto; padding: 24px; text-align: center; }
    .btn { display: inline-block; margin-top: 16px; padding: 12px 16px; border-radius: 8px; background: #ffffff; color: #121212; font-weight: 700; text-decoration: none; }
    .muted { opacity: .8; font-size: 14px; margin-top: 12px; }
    a.fallback { color: #c4d4ff; word-break: break-all; }
  </style>
</head>
<body>
  <div class="wrap">
    <h1>Paiement reussi</h1>
    <p>Retour automatique vers l'application...</p>
    <a class="btn" href="${safeOpenLink}">Ouvrir Anonym</a>
    <p class="muted">Lien web de secours :</p>
    <a class="fallback" href="${safeFallbackLink}">${safeFallbackLink}</a>
  </div>
</body>
</html>`);
});

app.get('/open-payment-cancel', (req, res) => {
    const webCancelLink = appendDeepLinkPath(getPaymentCancelWebBaseUrl(), '/app');
    const mobileCancelLink = appendDeepLinkPath(getPaymentCancelMobileBaseUrl(), '/app');
    const openLink = mobileCancelLink || webCancelLink;
    const fallbackLink = webCancelLink || '/';

    if (!openLink) {
        return res.status(500).type('text/plain').send("Aucun lien d'annulation configure.");
    }

    const safeOpenLink = escapeHtml(openLink);
    const safeFallbackLink = escapeHtml(fallbackLink);

    return res.status(200).type('html').send(`<!doctype html>
<html lang="fr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Retour vers Anonym</title>
  <meta http-equiv="refresh" content="0;url=${safeOpenLink}">
  <style>
    body { font-family: Arial, sans-serif; margin: 0; background: #121212; color: #f4f4f4; }
    .wrap { max-width: 460px; margin: 10vh auto; padding: 24px; text-align: center; }
    .btn { display: inline-block; margin-top: 16px; padding: 12px 16px; border-radius: 8px; background: #ffffff; color: #121212; font-weight: 700; text-decoration: none; }
    .muted { opacity: .8; font-size: 14px; margin-top: 12px; }
    a.fallback { color: #c4d4ff; word-break: break-all; }
  </style>
</head>
<body>
  <div class="wrap">
    <h1>Paiement annule</h1>
    <p>Retour automatique vers l'application...</p>
    <a class="btn" href="${safeOpenLink}">Ouvrir Anonym</a>
    <p class="muted">Lien web de secours :</p>
    <a class="fallback" href="${safeFallbackLink}">${safeFallbackLink}</a>
  </div>
</body>
</html>`);
});
/**
 * Routeur principal pour les API.
 * @function router
 * @param {string} route - Route définie pour l'API.
 * @param {Function} handler - Gestionnaire des requêtes pour les routes.
 */
app.use('/api', ensureCsrfCookie, router);

app.use((error, req, res, next) => {
    if (error instanceof multer.MulterError) {
        const message = error.code === 'LIMIT_FILE_SIZE'
            ? 'Image trop volumineuse.'
            : 'Fichier image invalide.';

        return res.status(400).json({ message });
    }

    return next(error);
});

module.exports = app;
