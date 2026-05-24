const jwt = require('jsonwebtoken');

/**
 * Middleware pour l'authentification des connexions Socket.io a l'aide de JWT.
 */
module.exports = (socket, next) => {
    try {
        const tokenFromQuery = socket?.handshake?.query?.token;
        const tokenFromAuth = socket?.handshake?.auth?.token;
        const authHeader = socket?.handshake?.headers?.authorization;
        const cookieHeader = socket?.handshake?.headers?.cookie;
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
            console.warn(`[SOCKET-AUTH] missing token socketId=${socket?.id || 'unknown'} origin=${socket?.handshake?.headers?.origin || 'unknown'}`);
            return next(new Error('Authentication error'));
        }

        const decodedToken = jwt.verify(token, process.env.JWT_SECRET);
        socket.userId = decodedToken.userId;
        console.log(`[SOCKET-AUTH] success socketId=${socket?.id || 'unknown'} userId=${socket.userId}`);

        return next();
    } catch (error) {
        console.warn(
            `[SOCKET-AUTH] failed socketId=${socket?.id || 'unknown'} reason=${error?.message || 'unknown'}`,
        );
        return next(new Error('Authentication error'));
    }
};
