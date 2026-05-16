const { User } = require('../models');
const bcrypt = require('bcrypt');
const fs = require('fs');
const path = require('path');

/**
 * @module userController
 * @description Ce module contient des fonctions pour gérer les données des utilisateurs, y compris la création, la mise à jour, la suppression d'utilisateurs et l'envoi de rapports.
 */

/**
 * Créer un nouvel utilisateur.
 * 
 * @async
 * @function create
 * @param {Object} req - L'objet de requête.
 * @param {Object} res - L'objet de réponse.
 * @throws {Object} 403 - Interdit si l'utilisateur n'a pas la permission de créer un utilisateur.
 * @throws {Object} 400 - Mauvaise requête si des champs requis sont manquants ou invalides.
 * @returns {Object} 201 - Objet utilisateur créé.
 * @returns {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la création de l'utilisateur.
 */
exports.create = async (req, res) => {
    try {
        const datas = JSON.parse(req.body.datas);
        const { username, email, password, roles, bio } = datas;
        let newAvatarPath;

        // Vérifier que l'utilisateur est soit ADMIN, soit SUPER_ADMIN
        if (req.auth.userRole === 'USER') {
            return res.status(403).json({ message: "You do not have permission to create a user." });
        }

        // Validation des champs requis
        if (!username) {
            return res.status(400).json({ message: "Username is required." });
        }

        if (!email) {
            return res.status(400).json({ message: "Email is required." });
        }

        if (!password) {
            return res.status(400).json({ message: "Password is required." });
        }

         // Regex pour valider le mot de passe
         const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+=\-[\]{};:,.<>?/\\|`~"'£¤§µ¢₹])[A-Za-z\d!@#$%^&*()_+=\-[\]{};:,.<>?/\\|`~"'£¤§µ¢₹]{12,}$/;
         if (!passwordRegex.test(password)) {
             return res.status(400).json({ message: "Mot de passe : 12 caractères min, avec majuscules, minuscules, chiffres et caractères spéciaux" });
         }

        // Vérifier si l'utilisateur tente de créer un rôle autre que 'USER'
        if (roles && roles !== 'USER') {
            // Vérifier si le rôle de l'utilisateur qui fait la requête est SUPER_ADMIN
            if (req.auth.userRole !== 'SUPER_ADMIN') {
                return res.status(403).json({ message: "Only SUPER_ADMIN can assign roles other than USER." });
            }
        }

        // Générer l'avatar si nécessaire
        if (!req.file) {
            const { circleColor, pathColor, uniqueAvatarName } = req.avatarData;

            // Chemin du fichier avatar par défaut
            const defaultAvatarPath = path.join(__dirname, '../../uploads/profiles/default/default_avatar.svg');
            const userAvatarPath = path.resolve(__dirname, '../../uploads/profiles/avatars', uniqueAvatarName);

            // Lire le contenu du SVG
            let svgContent = fs.readFileSync(defaultAvatarPath, 'utf8');

            // Remplacer les couleurs dans le SVG
            svgContent = svgContent.replace(/<circle[^>]*fill="[^"]*"[^>]*>/, `<circle cx="115" cy="115" r="115" fill="${circleColor}"/>`);
            svgContent = svgContent.replace(/<path[^>]*fill="[^"]*"[^>]*>/, `<path d="M114.37 48L150.593 117.743L167.732 116.319L184.87 114.894L158.396 132.766C169.932 154.979 184.87 183.741 184.87 183.741L161.077 183.801L140.549 144.814L66.4727 183.801H44L54.9652 162.64L135.365 133.027C135.365 133.027 135.396 133.016 135.457 132.994C136.576 132.584 177.708 117.529 184.87 114.894L167.732 116.319L150.593 117.743L131.372 124.824L115.018 92.3567L103.054 114.894L89.6156 140.207L44 157.012L66.0193 141.308L79.1852 115.9L114.37 48Z" fill="${pathColor}"/>`);

            // Enregistrer le SVG modifié
            fs.writeFileSync(userAvatarPath, svgContent);

            // Mettre à jour l'avatar de l'utilisateur
            newAvatarPath = `${req.protocol}://${req.get("host")}/uploads/profiles/avatars/${uniqueAvatarName}`;
        }else if (req.file) {
            // Définir le chemin du nouvel avatar
            newAvatarPath = `${req.protocol}://${req.get("host")}/uploads/profiles/avatars/${req.file.filename}`;
        }

        // Création de l'utilisateur avec les informations fournies
        const newUser = await User.create({
            username,
            email,
            password: password,
            roles: roles || 'USER', // Par défaut, le rôle est USER
            avatar: newAvatarPath,
            bio
        });

        res.status(201).json(newUser);
    } catch (error) {
        res.status(500).json({
            message: error.message || 'An error occurred while creating the user.'
        });
    }
};

/**
 * Mettre à jour un utilisateur existant.
 * 
 * @async
 * @function update
 * @param {Object} req - L'objet de requête.
 * @param {Object} res - L'objet de réponse.
 * @throws {Object} 403 - Interdit si l'utilisateur n'a pas la permission d'accéder à cette page.
 * @throws {Object} 404 - Non trouvé si l'utilisateur n'existe pas.
 * @throws {Object} 400 - Mauvaise requête si des champs requis sont invalides.
 * @returns {Object} 200 - Objet utilisateur mis à jour.
 * @returns {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la mise à jour de l'utilisateur.
 */
exports.update = async (req, res) => {
    try {
        const userId = req.params.id;
        const datas = JSON.parse(req.body.datas);
        const { username, email, password, avatar, roles, bio } = datas;

        if (req.auth.userRole === 'USER') {
            return res.status(403).json({ message: "Il faut être admin pour accéder à cette page." });
        }

        // Récupération de l'utilisateur cible
        const user = await User.findOne({ where: { id: userId } });
        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        // Vérification des permissions
        if (req.auth.userRole === 'ADMIN' && user.roles !== 'USER') {
            return res.status(403).json({ message: "Seul le SUPER_ADMIN peut attribuer des rôles autres que USER" });
        }

        let newAvatarPath = user.avatar;

        // Vérifier si l'avatar doit être supprimé
        if (req.avatarData && avatar === "delete") {
            // Supprimer l'ancien avatar
            if (user.avatar) {
                const oldAvatarPath = path.join(__dirname, '../../uploads/profiles/avatars', path.basename(user.avatar));
                if (fs.existsSync(oldAvatarPath)) {
                    fs.unlinkSync(oldAvatarPath); // Supprimer l'ancien fichier
                }
            }

            // Générer un nouvel avatar par défaut avec couleur modifiée
            if (!req.file && req.avatarData) {
                const { circleColor, pathColor, uniqueAvatarName } = req.avatarData;

                // Chemin du fichier avatar par défaut
                const defaultAvatarPath = path.join(__dirname, '../../uploads/profiles/default/default_avatar.svg');
                const userAvatarPath = path.resolve(__dirname, '../../uploads/profiles/avatars', uniqueAvatarName);

                // Lire le contenu du SVG
                let svgContent = fs.readFileSync(defaultAvatarPath, 'utf8');

                // Remplacer la couleur dans le SVG
                svgContent = svgContent.replace(/<circle[^>]*fill="[^"]*"[^>]*>/, `<circle cx="115" cy="115" r="115" fill="${circleColor}"/>`);
                svgContent = svgContent.replace(/<path[^>]*fill="[^"]*"[^>]*>/, `<path d="M114.37 48L150.593 117.743L167.732 116.319L184.87 114.894L158.396 132.766C169.932 154.979 184.87 183.741 184.87 183.741L161.077 183.801L140.549 144.814L66.4727 183.801H44L54.9652 162.64L135.365 133.027C135.365 133.027 135.396 133.016 135.457 132.994C136.576 132.584 177.708 117.529 184.87 114.894L167.732 116.319L150.593 117.743L131.372 124.824L115.018 92.3567L103.054 114.894L89.6156 140.207L44 157.012L66.0193 141.308L79.1852 115.9L114.37 48Z" fill="${pathColor}"/>`);

                // Enregistrer le SVG modifié
                fs.writeFileSync(userAvatarPath, svgContent);

                // Mettre à jour l'avatar de l'utilisateur dans la base de données
                newAvatarPath = `${req.protocol}://${req.get("host")}/uploads/profiles/avatars/${uniqueAvatarName}`;
            }
        } else if (req.file) {
            // Définir le chemin du nouvel avatar
            newAvatarPath = `${req.protocol}://${req.get("host")}/uploads/profiles/avatars/${req.file.filename}`;

            // Supprimer l'ancien avatar
            if (user.avatar) {
                const oldAvatarPath = path.join(__dirname, '../../uploads/profiles/avatars', path.basename(user.avatar));
                if (fs.existsSync(oldAvatarPath)) {
                    fs.unlinkSync(oldAvatarPath); // Supprimer le fichier
                }
            }
        }

        // Mise à jour des informations de l'utilisateur
        if (username) {
            // Valider le username
            const usernameRegex = /^(?=.*[a-zA-Z])(?=^[A-Za-z0-9_-]{3,15}$)/; // Regex pour le username
            if (!usernameRegex.test(username)) {
                return res.status(400).json({
                    message: "Le nom d'utilisateur doit contenir entre 3 et 15 caractères, inclure au moins une lettre, et peut contenir des chiffres, des tirets et des tirets du bas."
                });
            }
            user.username = username;
        }
        if (email) user.email = email;
        if (password) user.password = await bcrypt.hash(password, 10);
        if (typeof bio === 'string' || bio === null) user.bio = bio;
        // Vérifier si l'utilisateur tente de créer un rôle autre que 'USER'
        if (roles && roles !== 'USER') {
            // Vérifier si le rôle de l'utilisateur qui fait la requête est SUPER_ADMIN
            if (req.auth.userRole !== 'SUPER_ADMIN') {
                return res.status(403).json({ message: "Seul le SUPER_ADMIN peut attribuer des rôles autres que USER" });
            }
        }
        user.roles = roles;
        user.avatar = newAvatarPath;

        await user.save();

        res.status(200).json(user);
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while updating the user.' });
    }
};

/**
 * Supprimer un utilisateur existant.
 * 
 * @async
 * @function deleteUser
 * @param {Object} req - L'objet de requête.
 * @param {Object} res - L'objet de réponse.
 * @throws {Object} 403 - Interdit si l'utilisateur n'a pas la permission de supprimer un utilisateur.
 * @throws {Object} 404 - Non trouvé si l'utilisateur n'existe pas.
 * @returns {Object} 200 - Message de succès indiquant que l'utilisateur a été supprimé.
 * @returns {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la suppression de l'utilisateur.
 */
exports.delete = async (req, res) => {
    try {
        const userId = req.params.id;

        if (req.auth.userRole === 'USER') {
            return res.status(403).json({ message: "Il faut être admin pour accéder à cette page." });
        }

        // Récupération de l'utilisateur cible
        const user = await User.findOne({ where: { id: userId } });
        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        // Vérification des permissions
        if (req.auth.userRole === 'ADMIN' && user.roles !== 'USER') {
            return res.status(403).json({ message: "Admins can only delete users with role USER." });
        }

        // Supprimer l'avatar
        if (user.avatar) {
            const avatarPath = path.join(__dirname, '../../uploads/profiles/avatars', path.basename(user.avatar));
            fs.unlink(avatarPath, (err) => {
                if (err) {
                    console.error("Error deleting avatar file:", err);
                }
            });
        }

        await user.destroy();

        res.status(200).json({ message: "User deleted successfully." });
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while deleting the user.' });
    }
};

/**
 * Envoyer un rapport sur un utilisateur.
 * 
 * @async
 * @function reportUser
 * @param {Object} req - L'objet de requête.
 * @param {Object} res - L'objet de réponse.
 * @throws {Object} 404 - Non trouvé si l'utilisateur à signaler n'existe pas.
 * @returns {Object} 200 - Message de succès confirmant que le rapport a été envoyé.
 * @returns {Object} 500 - Erreur interne du serveur si une erreur se produit lors de l'envoi du rapport.
 */
exports.report = async (req, res) => {
    const { email, type, content } = req.body;
    try {
        // Vérifier que tous les champs nécessaires sont présents
        if (!email || !type || !content) {
            return res.status(400).json({ message: "Veuillez fournir votre email, un type et un contenu." });
        }

        // Rechercher l'utilisateur par email
        const user = await User.findOne({ where: { email: email } });
        if (!user) {
            return res.status(404).json({ message: "Utilisateur non trouvé avec cet email" });
        }

        // Si l'utilisateur est trouvé, on peut récupérer son nom d'utilisateur
        const username = user.username;

        // Charger le template de l'email pour le rapport
        const emailTemplatePath = path.join(__dirname, '../../templates/report-email.html');
        let emailHtmlContent = fs.readFileSync(emailTemplatePath, 'utf8');
        
        // Remplacer {{username}} et {{description}} par les valeurs correspondantes
        emailHtmlContent = emailHtmlContent
            .replace(/{{username}}/g, username)
            .replace(/{{description}}/g, content)
            .replace(/{{email}}/g, email);

        // Créer le sujet de l'email basé sur le type de rapport
        const subject = `Rapport - Type: ${type}`;

        // Envoyer l'email avec les informations
        await req.mailer.sendEmail(
            'lukasbouhlel@gmail.com',             // Adresse de l'utilisateur
            subject,           // Sujet de l'email
            '',                // Texte brut vide car on utilise HTML
            emailHtmlContent   // Contenu HTML
        );

        // Répondre avec un succès
        res.status(200).json({ message: "Email de rapport envoyé avec succès." });
    } catch (error) {
        console.error("Error during report sending:", error);
        res.status(500).json({ message: error.message || "Une erreur s'est produite lors de l'envoi du rapport." });
    }
};
