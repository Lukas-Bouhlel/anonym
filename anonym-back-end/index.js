require('dotenv').config();
const app = require("./app.js");
const { createServer } = require("http");
const { Server } = require("socket.io");
const initializeSocket = require('./app/utils/socket');
const socketAuth = require('./app/middlewares/socketAuth');
const env = process.env.NODE_ENV || 'development';
const port = process.env.NODE_ENV === 'preprod' ? process.env.PORT_PREPROD : process.env.PORT;

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

/**
 * Création du serveur HTTPS
 * 
 * @function createServer
 * @param {Object} app - L'application Express à utiliser avec le serveur HTTPS.
 */
const httpServer = createServer(app);

/**
 * Configuration du serveur Socket.IO
 * 
 * @constant {Server} io - Instance de Socket.IO attachée au serveur HTTPS.
 * @property {Object} cors - Configuration CORS pour gérer les autorisations d'origine et les méthodes HTTP.
 * @property {string} cors.origin - Origine autorisée (définie via la variable d'environnement `ORIGIN`).
 * @property {boolean} cors.credentials - Indique si les cookies sont autorisés pour les requêtes cross-origin.
 * @property {Array<string>} cors.methods - Méthodes HTTP autorisées par CORS.
 * @property {Array<string>} cors.allowedHeaders - Headers autorisés dans les requêtes CORS.
 */
const io = new Server(httpServer, {
  cors: {
      origin: (origin, callback) => {
        if (isAllowedOrigin(origin)) {
          return callback(null, true);
        }
        return callback(new Error(`Origin not allowed by CORS: ${origin}`), false);
      },
      credentials: true,
      methods: ['GET', 'POST', 'PUT', 'DELETE'],
      allowedHeaders: ['Content-Type', 'Authorization']
  }
});

io.use(socketAuth);

/**
 * Lancement du serveur HTTPS et Socket.IO
 * 
 * @function listen
 * @param {number} port - Port sur lequel l'application et Socket.IO écouteront les connexions (défini via la variable d'environnement `PORT`).
 */
httpServer.listen(port, () => {
  console.log(`App and Socket.IO listening on port ${port}`);
});

/**
 * Exposition de l'instance io pour les contrôleurs
 */
app.locals.io = io;

/**
 * Initialisation des sockets
 * 
 * @function initializeSocket
 * @param {Server} io - Instance de Socket.IO pour gérer les connexions des sockets.
 */
initializeSocket(io);
