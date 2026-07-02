const jwt = require('jsonwebtoken');

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
        const tokenFromCookie = req.cookies?.token;
        const authHeader = req.headers?.authorization;
        const tokenFromHeader = authHeader && authHeader.startsWith('Bearer ')
            ? authHeader.slice(7)
            : null;
        const token = tokenFromCookie || tokenFromHeader;

        if (!token) {
            throw new Error('Missing token');
        }

        const decodedToken = jwt.verify(token, process.env.JWT_SECRET);
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
        res.clearCookie?.(process.env.JWT_ACCESS_COOKIE_NAME || 'token', cookieOptions);
        res.status(401).json({
            error: 'Unauthorized request!'
        });
    }
};
