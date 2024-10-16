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
        const token = req.cookies.token; 

        const decodedToken = jwt.verify(token, process.env.JWT_SECRET);
        const userId = decodedToken.userId;
        const userRole = decodedToken.userRole;

        req.auth = {
            userId,
            userRole
        };
        
        next();
    } catch {
        res.status(401).json({
            error: 'Unauthorized request!'
        });
    }
};