const jwt = require('jsonwebtoken');

/**
 * Middleware pour l'authentification des connexions Socket.io à l'aide de JWT.
 * 
 * Ce middleware vérifie si un token JWT est présent dans la requête de connexion
 * et l'authentifie. Si le token est valide, l'ID utilisateur est attaché au socket
 * pour un accès ultérieur dans les événements de socket.
 * 
 * @param {Object} socket - L'objet Socket.io représentant la connexion du client.
 * @param {Function} next - La fonction de rappel pour passer au prochain middleware ou gérer une erreur.
 * 
 * @throws {Error} Si le token n'est pas présent ou est invalide.
 * 
 * @example
 * // Exemple d'utilisation dans un serveur Socket.io
 * const io = require('socket.io')(server);
 * io.use(require('./path/to/your/middleware'));
 * 
 * io.on('connection', (socket) => {
 *     console.log(`User connected: ${socket.userId}`);
 * });
 */
module.exports = (socket, next) => {
    try {
        const token = socket.handshake.query.token; // Récupère le token envoyé lors de la connexion socket.io

        if (!token) {
            return next(new Error('Authentication error'));
        }

        const decodedToken = jwt.verify(token, process.env.JWT_SECRET);

        socket.userId = decodedToken.userId; // Attache l'ID utilisateur au socket pour les événements futurs

        next(); // Appelle next() pour continuer si tout est correct
    } catch {
        next(new Error('Authentication error'));
    }
};