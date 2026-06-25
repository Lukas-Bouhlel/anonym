const jwt = require('jsonwebtoken');

/**
 * Middleware pour l'authentification des connexions Socket.io a l'aide de JWT.
 */
module.exports = (socket, next) => {
    if (!socket) {
        return next(new Error('Authentication error'));
    }

    try {
        const handshake = socket.handshake || {};
        const headers = handshake.headers || {};
        const tokenFromQuery = handshake.query?.token;
        const tokenFromAuth = handshake.auth?.token;
        const authHeader = headers.authorization;
        const cookieHeader = headers.cookie;
        const tokenFromHeader = typeof authHeader === 'string' && authHeader.startsWith('Bearer ')
            ? authHeader.slice(7)
            : null;
        const tokenFromCookie = (() => {
            if (typeof cookieHeader !== 'string' || cookieHeader.trim().length === 0) {
                return null;
            }
            const parts = cookieHeader.split(';');
            for (const part of parts) {
                const [rawKey, ...rawValueParts] = part.trim().split('=');
                if (rawKey !== 'token') continue;
                const rawValue = rawValueParts.join('=').trim();
                if (!rawValue) return null;
                try {
                    return decodeURIComponent(rawValue);
                } catch {
                    return rawValue;
                }
            }
            return null;
        })();

        const token = tokenFromAuth || tokenFromQuery || tokenFromHeader || tokenFromCookie;

        if (!token) {
            console.warn(`[SOCKET-AUTH] missing token socketId=${socket.id || 'unknown'} origin=${headers.origin || 'unknown'}`);
            return next(new Error('Authentication error'));
        }

        const decodedToken = jwt.verify(token, process.env.JWT_SECRET);
        socket.userId = decodedToken.userId;
        console.log(`[SOCKET-AUTH] success socketId=${socket.id || 'unknown'} userId=${socket.userId}`);

        return next();
    } catch (error) {
        console.warn(
            `[SOCKET-AUTH] failed socketId=${socket.id || 'unknown'} reason=${error?.message || 'unknown'}`,
        );
        return next(new Error('Authentication error'));
    }
};
