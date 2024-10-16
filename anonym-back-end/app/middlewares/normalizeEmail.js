/**
 * Middleware pour normaliser les adresses e-mail, en particulier celles de Gmail.
 * 
 * Ce middleware supprime les points (.) du local part des adresses e-mail 
 * qui appartiennent aux domaines Gmail (`gmail.com`, `googlemail.com`).
 * 
 * @param {Object} req - L'objet de requête Express.
 * @param {Object} res - L'objet de réponse Express.
 * @param {Function} next - La fonction de rappel pour passer au middleware suivant.
 * 
 * @example
 * // Exemple d'utilisation dans une route
 * app.post('/signup', normalizeEmail, (req, res) => {
 *     // L'adresse e-mail sera normalisée avant d'atteindre ce point.
 *     res.send('Email normalisé : ' + req.body.email);
 * });
 */
function normalizeEmail(req, res, next) {
    const gmailDomains = ['gmail.com', 'googlemail.com'];
    
    if (req.body.email) {
        const [localPart, domainPart] = req.body.email.split('@');
        if (gmailDomains.includes(domainPart.toLowerCase())) {
            req.body.email = localPart.replace(/\./g, '') + '@' + domainPart;
        }
    } else if(req.body.identifier) {
        const [localPart, domainPart] = req.body.identifier.split('@');
        if (domainPart && gmailDomains.includes(domainPart.toLowerCase())) {
            req.body.identifier = localPart.replace(/\./g, '') + '@' + domainPart;
        }
    }
    next();
}

module.exports = normalizeEmail;