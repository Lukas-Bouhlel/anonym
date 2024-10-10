const jwt = require('jsonwebtoken');

module.exports = (socket, next) => {
    try {
        const token = socket.handshake.query.token; // Récupère le token envoyé lors de la connexion socket.io

        if (!token) {
            return next(new Error('Authentication error'));
        }

        const decodedToken = jwt.verify(token, process.env.JWT_SECRET);

        socket.userId = decodedToken.userId; // Attache l'ID utilisateur au socket pour les événements futurs

        next(); // Appelle next() pour continuer si tout est correct
    } catch (error) {
        next(new Error('Authentication error'));
    }
};