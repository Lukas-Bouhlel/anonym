/**
 * @module middlewares/generateAvatar
 * @description Middleware pour générer des couleurs aléatoires pour un avatar.
 */

/**
 * Génère une couleur pastel aléatoire.
 *
 * @function
 * @returns {string} La couleur pastel générée au format hexadécimal.
 */
function generatePastelColor() {
    const red = Math.floor((Math.random() * 128) + 128); // 128 à 255
    const green = Math.floor((Math.random() * 128) + 128);
    const blue = Math.floor((Math.random() * 128) + 128);
    return `#${red.toString(16).padStart(2, '0')}${green.toString(16).padStart(2, '0')}${blue.toString(16).padStart(2, '0')}`;
}

/**
 * Détermine si une couleur est sombre.
 *
 * @function
 * @param {string} color - La couleur au format hexadécimal.
 * @returns {boolean} Vrai si la couleur est sombre, faux sinon.
 */
function isDarkColor(color) {
    const r = parseInt(color.slice(1, 3), 16);
    const g = parseInt(color.slice(3, 5), 16);
    const b = parseInt(color.slice(5, 7), 16);

    // Calculer la luminosité de la couleur
    const brightness = (r * 299 + g * 587 + b * 114) / 1000;
    // Ajuster le seuil de luminosité
    return brightness < 200; // Valeur seuil pour distinguer les couleurs sombres des claires
}

/**
 * Middleware pour générer des couleurs aléatoires pour l'avatar.
 *
 * Si aucun fichier d'avatar n'est fourni dans la requête, ce middleware génère une couleur pastel aléatoire
 * et détermine la couleur du chemin en fonction de la luminosité de la couleur du cercle.
 * Les couleurs générées et le nom unique de l'avatar sont attachés à `req.avatarData`.
 *
 * @function
 * @param {Object} req - L'objet de requête Express.
 * @param {Object} res - L'objet de réponse Express.
 * @param {function} next - La fonction pour passer au middleware suivant.
 * @returns {void}
 */
module.exports = (req, res, next) => {
    try {
        if (!req.file && !req.body.avatar) {
            // Générer une couleur pastel aléatoire pour le cercle
            const circleColor = generatePastelColor();
            // Déterminer la couleur du chemin en fonction de la couleur du cercle
            const pathColor = isDarkColor(circleColor) ? '#FFF9F4' : '#333333';

            // Attacher les couleurs générées et le nom de l'avatar à la requête
            req.avatarData = {
                circleColor,
                pathColor,
                uniqueAvatarName: `avatar_${Date.now()}.svg`,
            };
        }
        next();
    } catch (error) {
        res.status(500).json({ 
            message: error.message || 'Could not process avatar generation' 
        });
    }
};