/**
 * @module middlewares/authorizeAdmin
 * @description Middleware pour autoriser l'accès uniquement aux utilisateurs ayant un rôle d'administrateur.
 */

/**
 * Middleware d'autorisation d'administrateur.
 *
 * Ce middleware vérifie le rôle de l'utilisateur stocké dans `req.auth.userRole`.
 * Si l'utilisateur n'a pas le rôle d'Admin, il renvoie une réponse 403 Forbidden.
 * Sinon, il appelle la fonction `next()` pour passer au middleware suivant.
 *
 * @function
 * @param {Object} req - L'objet de requête Express contenant les informations sur l'utilisateur authentifié.
 * @param {Object} res - L'objet de réponse Express utilisé pour renvoyer des réponses au client.
 * @param {function} next - La fonction pour passer au middleware suivant.
 * @returns {void}
 */
const authorizeAdmin = (req, res, next) => {
    if (req.auth.userRole === 'User') {
        return res.status(403).json({ message: 'Accès interdit, vous devez être Admin.' });
    }

    next();
};

module.exports = authorizeAdmin;