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

const getCookieValues = (req, name) => {
    const values = [];
    const cookieHeader = req.headers?.cookie;

    if (typeof cookieHeader === 'string' && cookieHeader.trim().length > 0) {
        for (const part of cookieHeader.split(';')) {
            const [rawKey, ...rawValueParts] = part.trim().split('=');
            if (rawKey !== name) continue;
            appendUnique(values, decodeCookieValue(rawValueParts.join('=').trim()));
        }
    }

    appendUnique(values, req.cookies?.[name]);
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
 * @module middlewares/auth
 * @description Middleware d'authentification qui vérifie le token JWT pour autoriser ou refuser l'accès aux routes protégées.
 */

/**
 * Middleware d'authentification.
 * 
 * Ce middleware vérifie le token JWT dans les cookies de la requête, le décode,
 * et ajoute les informations d'utilisateur (userId et userRole) à l'objet `req.auth`.
 * Si le token est valide, il appelle `next()` pour passer au middleware suivant.
 * Sinon, il renvoie une réponse 401 Unauthorized.
 * 
 * @function
 * @param {Object} req - L'objet de requête Express.
 * @param {Object} res - L'objet de réponse Express.
 * @param {function} next - La fonction pour passer au middleware suivant.
 * @throws {Error} Renvoie une erreur si le token est invalide ou absent.
 */
module.exports = (req, res, next) => {
    try {
        const authHeader = req.headers?.authorization;
        const tokenFromHeader = authHeader && authHeader.startsWith('Bearer ')
            ? authHeader.slice(7)
            : null;
        const tokenCandidates = getCookieValues(req, ACCESS_COOKIE_NAME);
        appendUnique(tokenCandidates, tokenFromHeader);

        if (tokenCandidates.length === 0) {
            throw new Error('Missing token');
        }

        const decodedToken = verifyFirstValidToken(tokenCandidates);
        const userId = decodedToken.userId;
        const userRole = decodedToken.userRole;

        req.auth = {
            userId,
            userRole
        };
        
        next();
    } catch {
        const cookieOptions = {
            httpOnly: true,
            secure: process.env.NODE_ENV === 'production',
            sameSite: 'Strict',
        };
        res.clearCookie?.(ACCESS_COOKIE_NAME, cookieOptions);
        res.status(401).json({
            error: 'Unauthorized request!'
        });
    }
};
