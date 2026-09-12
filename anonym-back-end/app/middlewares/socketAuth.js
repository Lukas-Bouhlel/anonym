const jwt = require('jsonwebtoken');

const ACCESS_COOKIE_NAME = process.env.JWT_ACCESS_COOKIE_NAME || 'token';

const decodeCookieValue = (value) => {
    try {
        return decodeURIComponent(value);
    } catch {
        return value;
    }
};

const appendUnique = (values, value) => {
    if (typeof value !== 'string') return;
    const normalized = value.trim();
    if (!normalized || values.includes(normalized)) return;
    values.push(normalized);
};

const getCookieValues = (cookieHeader, name) => {
    const values = [];
    if (typeof cookieHeader !== 'string' || cookieHeader.trim().length === 0) {
        return values;
    }

    for (const part of cookieHeader.split(';')) {
        const [rawKey, ...rawValueParts] = part.trim().split('=');
        if (rawKey !== name) continue;
        appendUnique(values, decodeCookieValue(rawValueParts.join('=').trim()));
    }
    return values;
};

const verifyFirstValidToken = (tokens) => {
    let lastError = null;
    for (const token of tokens) {
        try {
            return jwt.verify(token, process.env.JWT_SECRET);
        } catch (error) {
            lastError = error;
        }
    }
    throw lastError || new Error('Missing token');
};

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
        const tokenCandidates = [];

        appendUnique(tokenCandidates, tokenFromAuth);
        appendUnique(tokenCandidates, tokenFromQuery);
        appendUnique(tokenCandidates, tokenFromHeader);
        getCookieValues(cookieHeader, ACCESS_COOKIE_NAME).forEach((token) => appendUnique(tokenCandidates, token));

        if (tokenCandidates.length === 0) {
            console.warn(`[SOCKET-AUTH] missing token socketId=${socket.id || 'unknown'} origin=${headers.origin || 'unknown'}`);
            return next(new Error('Authentication error'));
        }

        const decodedToken = verifyFirstValidToken(tokenCandidates);
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
