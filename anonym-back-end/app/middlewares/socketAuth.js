const jwt = require('jsonwebtoken');

/**
 * Middleware pour l'authentification des connexions Socket.io a l'aide de JWT.
 */
module.exports = (socket, next) => {
    try {
        const tokenFromQuery = socket?.handshake?.query?.token;
        const tokenFromAuth = socket?.handshake?.auth?.token;
        const authHeader = socket?.handshake?.headers?.authorization;
        const tokenFromHeader = typeof authHeader === 'string' && authHeader.startsWith('Bearer ')
            ? authHeader.slice(7)
            : null;

        const token = tokenFromAuth || tokenFromQuery || tokenFromHeader;

        if (!token) {
            return next(new Error('Authentication error'));
        }

        const decodedToken = jwt.verify(token, process.env.JWT_SECRET);
        socket.userId = decodedToken.userId;

        return next();
    } catch {
        return next(new Error('Authentication error'));
    }
};
