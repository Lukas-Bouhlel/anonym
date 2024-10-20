const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const rateLimit = require('express-rate-limit'); 
const slowDown = require('express-slow-down'); 
const app = express();
const helmet = require('helmet');
const router = require("./app/routes/index.js");
const db = require("./app/models/index.js");
const path = require('path');
const createMailer = require('./app/utils/mailer.js');
const env = process.env.NODE_ENV || 'development';

/**
 * Connexion à la base de données avec Sequelize.
 * @function authenticate
 * @memberof sequelize
 * @returns {Promise} - Résolution de la promesse si la connexion à la base de données est réussie.
 */
db.sequelize
    .authenticate()
    .then(() => console.log("Database connected..."))
    .catch((err) => console.log(err));

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
    max: 500, // Limite chaque IP à 500 requêtes par fenêtre
    message: {
        message: "Trop de requêtes effectuées depuis cette adresse IP, veuillez réessayer plus tard.",
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
    delayAfter: 50, // Commence à ralentir les requêtes après 50 requêtes dans la fenêtre
    delayMs: () => 500, // Délai fixe de 500 ms par requête supplémentaire
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
            imgSrc: ["'self'",  env === 'production' ? process.env.ORIGIN_PROD : process.env.ORIGIN, "data:"],  // Permettre le chargement d'images depuis localhost:5000 et les données inline (pour les avatars par ex)
            scriptSrc: ["'self'", env === 'production' ? process.env.ORIGIN_PROD : process.env.ORIGIN],  // Permettre les scripts depuis localhost:5000
            styleSrc: ["'self'", "'unsafe-inline'"],  // Permet les styles inline (facultatif)
            fontSrc: ["'self'", env === 'production' ? process.env.ORIGIN_PROD : process.env.ORIGIN],  // Permettre les polices de caractères depuis localhost:5000
            connectSrc: ["'self'", env === 'production' ? process.env.ORIGIN_PROD : process.env.ORIGIN], // Autoriser les connexions à localhost:5000 (pour les API, WebSocket, etc.)
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
    origin: env === 'production' ? process.env.ORIGIN_PROD : process.env.ORIGIN, 
    credentials: true,  // Permet les cookies
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization']
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
/**
 * Routeur principal pour les API.
 * @function router
 * @param {string} route - Route définie pour l'API.
 * @param {Function} handler - Gestionnaire des requêtes pour les routes.
 */
app.use("/api", router);

module.exports = app;