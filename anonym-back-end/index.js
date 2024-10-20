require('dotenv').config();
const app = require("./app.js");
const port = process.env.PORT;
const { createServer } = require("http");
const { Server } = require("socket.io");
const initializeSocket = require('./app/utils/socket');
const env = process.env.NODE_ENV || 'development';

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
      origin: env === 'production' ? process.env.ORIGIN_PROD : process.env.ORIGIN, 
      credentials: true,
      methods: ['GET', 'POST', 'PUT', 'DELETE'],
      allowedHeaders: ['Content-Type', 'Authorization']
  }
});

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
 * Initialisation des sockets
 * 
 * @function initializeSocket
 * @param {Server} io - Instance de Socket.IO pour gérer les connexions des sockets.
 */
initializeSocket(io);