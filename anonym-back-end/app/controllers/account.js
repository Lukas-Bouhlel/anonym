const { User, Inventory, Shop, Channel, PrivateMessage } = require('../models');
const bcrypt = require('bcrypt');
const fs = require('fs');
const path = require('path');
const { Op } = require('sequelize');
const { deleteUploadFileIfExists, deleteUploadFiles } = require('../utils/fileCleanup');
let hasAllowNonFriendDmsColumnCache = null;

const hasAllowNonFriendDmsColumn = async () => {
    if (hasAllowNonFriendDmsColumnCache !== null) {
        return hasAllowNonFriendDmsColumnCache;
    }

    try {
        const usersTable = await User.sequelize.getQueryInterface().describeTable('users');
        hasAllowNonFriendDmsColumnCache = Boolean(usersTable.allow_non_friend_dms);
    } catch {
        hasAllowNonFriendDmsColumnCache = false;
    }

    return hasAllowNonFriendDmsColumnCache;
};

/**
 * @module UserController
 */

/**
 * Récupère les informations du compte de l'utilisateur connecté, y compris l'inventaire actif.
 *
 * @function readAccount
 * @async
 * @param {Object} req - La requête HTTP.
 * @param {Object} res - La réponse HTTP.
 * @throws {Error} En cas d'erreur lors de la récupération des informations de l'utilisateur.
 */
exports.readAccount = async (req, res) => {
    try {
        const userId = req.auth.userId;// Récupérer l'ID de l'utilisateur depuis les paramètres JWT

        // Trouver l'utilisateur par ID avec findOne
        const user = await User.findOne({
            where: { id: userId },
            include: [
                {
                    model: Inventory,
                    where: { active: true }, // Ne récupérer que les articles actifs
                    include: [
                        {
                            model: Shop, // Inclure les informations sur l'article depuis le modèle Shop
                            attributes: ['title', 'type', 'content', 'amount']
                        }
                    ],
                    required: false
                }
            ]
        });

        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        res.status(200).json(user);
    } catch (error) {
        res.status(500).json({
            message: error.message || 'Une erreur est survenue lors de la récupération des comptes.'
        });
    }
};

/**
 * Récupère les informations d'un utilisateur par son ID.
 *
 * @function read
 * @async
 * @param {Object} req - La requête HTTP.
 * @param {Object} res - La réponse HTTP.
 * @throws {Error} En cas d'erreur lors de la récupération de l'utilisateur.
 */
exports.read = async (req, res) => {
    try {
        const userId = req.params.id;
        const user = await User.findOne({
            where: { id: userId },
            attributes: { exclude: ['password'] } // Exclure le champ 'password'
        });

        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        res.status(200).json(user);
    } catch (error) {
        res.status(500).json({
            message: error.message || 'Une erreur est survenue lors de la récupération du compte.'
        });
    }
};

/**
 * Récupère tous les utilisateurs, en excluant le champ 'password'.
 *
 * @function readAll
 * @async
 * @param {Object} req - La requête HTTP.
 * @param {Object} res - La réponse HTTP.
 * @throws {Error} En cas d'erreur lors de la récupération des utilisateurs.
 */
exports.readAll = async (req, res) => {
    try {
        const users = await User.findAll({
            attributes: { exclude: ['password'] } // Exclure le champ 'password'
        });

        if (!users) {
            return res.status(404).json({ message: "Users not found" });
        }

        res.status(200).json(users);
    } catch (error) {
        res.status(500).json({
            message: error.message || 'Une erreur est survenue lors de la récupération des comptes.'
        });
    }
};

/**
 * Met à jour les informations d'un utilisateur.
 *
 * @function update
 * @async
 * @param {Object} req - La requête HTTP.
 * @param {Object} res - La réponse HTTP.
 * @throws {Error} En cas d'erreur lors de la mise à jour de l'utilisateur.
 *
 * @example
 * // Exemple de requête
 * PATCH /api/users/update
 * {
 *   "datas": {
 *     "username": "nouveau_nom",
 *     "email": "nouvel_email@example.com",
 *     "avatar": "delete"
 *   }
 * }
 */
exports.update = async (req, res) => {
    try {
        const userId = req.auth.userId;// Récupérer l'ID de l'utilisateur depuis les paramètres JWT
        const datas = JSON.parse(req.body.datas);
        const { username, email, avatar, bio, allow_non_friend_dms } = datas;

        if (!userId) {
            return res.status(400).json({ message: "User ID is required." });
        }

        // Trouver l'utilisateur par ID
        const user = await User.findOne({ where: { id: userId } });

        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        let newAvatarPath = user.avatar;
        // Vérifier si l'avatar doit être supprimé
        if (req.avatarData && avatar === "delete") {
            // Supprimer l'ancien avatar
            deleteUploadFileIfExists(user.avatar);

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
            deleteUploadFileIfExists(user.avatar);
        }

        // Mise à jour des informations de l'utilisateur
        if (username) {
            // Valider le username
            const usernameRegex = /^(?=.*[a-zA-Z])(?=^[A-Za-z0-9_-]{3,15}$)/; // Regex pour le username
            if (!usernameRegex.test(username)) {
                return res.status(400).json({
                    message: "Nom d'utilisateur : 3 à 15 caractères, min une lettre, et peut contenir des chiffres, des tirets et des tirets du bas"
                });
            }
            user.username = username;
        }
        if (email) user.email = email;
        if (typeof bio === 'string' || bio === null) user.bio = bio;
        if (typeof allow_non_friend_dms === 'boolean' && await hasAllowNonFriendDmsColumn()) {
            user.allow_non_friend_dms = allow_non_friend_dms;
        }
        user.avatar = newAvatarPath;

        await user.save();

        res.status(200).json(user);
    } catch (error) {
        res.status(500).json({
            message: error.message || 'Une erreur est survenue lors de la mise à jour du compte.'
        });
    }
};

/**
 * Met à jour le mot de passe d'un utilisateur.
 *
 * @function updatePassword
 * @async
 * @param {Object} req - La requête HTTP.
 * @param {Object} res - La réponse HTTP.
 * @throws {Error} En cas d'erreur lors de la mise à jour du mot de passe.
 */
exports.updatePassword = async (req, res) => {
    try {
        const userId = req.auth.userId; // Récupérer l'ID de l'utilisateur via JWT
        const { currentPassword, newPassword, confirmNewPassword } = req.body;

        // Vérification des champs
        if (!currentPassword || !newPassword || !confirmNewPassword) {
            return res.status(400).json({ message: "Tous les champs sont obligatoires." });
        }

        // Vérifier que le nouveau mot de passe correspond à la confirmation
        if (newPassword !== confirmNewPassword) {
            return res.status(400).json({ message: "Les nouveaux mots de passe ne correspondent pas." });
        }

        // Regex pour valider le mot de passe
        const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+=\-[\]{};:,.<>?/\\|`~"'£¤§µ¢₹])[A-Za-z\d!@#$%^&*()_+=\-[\]{};:,.<>?/\\|`~"'£¤§µ¢₹]{12,}$/;
        if (!passwordRegex.test(newPassword)) {
            return res.status(400).json({ message: "Mot de passe : 12 caractères min, avec majuscules, minuscules, chiffres et caractères spéciaux" });
        }

        // Trouver l'utilisateur dans la base de données
        const user = await User.findOne({ where: { id: userId } });

        if (!user) {
            return res.status(404).json({ message: "Utilisateur non trouvé." });
        }

        // Vérifier que le mot de passe actuel est correct
        const passwordMatch = await bcrypt.compare(currentPassword, user.password);
        if (!passwordMatch) {
            return res.status(401).json({ message: "Mot de passe actuel incorrect." });
        }

        // Hacher le nouveau mot de passe
        const hashedNewPassword = await bcrypt.hash(newPassword, 10);

        // Mettre à jour le mot de passe de l'utilisateur
        user.password = hashedNewPassword;
        await user.save();

        res.status(200).json({ message: "Mot de passe mis à jour avec succès." });
    } catch (error) {
        res.status(500).json({
            message: error.message || "Une erreur est survenue lors de la mise à jour du mot de passe."
        });
    }
};

/**
 * Supprime un utilisateur et son avatar.
 *
 * @function delete
 * @async
 * @param {Object} req - La requête HTTP.
 * @param {Object} res - La réponse HTTP.
 * @throws {Error} En cas d'erreur lors de la suppression de l'utilisateur.
 */
exports.delete = async (req, res) => {
    try {
        const userId = req.auth.userId;// Récupérer l'ID de l'utilisateur depuis les paramètres JWT

        if (!userId) {
            return res.status(400).json({ message: "User ID is required." });
        }

        // Trouver l'utilisateur par ID
        const user = await User.findOne({ where: { id: userId } });

        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        const createdChannels = await Channel.findAll({
            where: { created_by: userId },
            attributes: ['channel_id', 'cover_image'],
            raw: true
        });
        const createdChannelIds = createdChannels.map((channel) => channel.channel_id);

        const messageWhere = [{ sender_id: userId }];
        if (createdChannelIds.length > 0) {
            messageWhere.push({ channel_id: { [Op.in]: createdChannelIds } });
        }

        const messagesWithImages = await PrivateMessage.findAll({
            where: {
                image_url: { [Op.ne]: null },
                [Op.or]: messageWhere
            },
            attributes: ['image_url'],
            raw: true
        });

        deleteUploadFiles([
            user.avatar,
            ...createdChannels.map((channel) => channel.cover_image),
            ...messagesWithImages.map((message) => message.image_url)
        ]);

        res.clearCookie('token', {
            httpOnly: true,
            secure: process.env.NODE_ENV === 'production',
            sameSite: 'Strict',
        });

        // Supprimer l'utilisateur
        await user.destroy();

        res.status(200).json({ message: "User deleted successfully" });
    } catch (error) {
        res.status(500).json({
            message: error.message || 'Une erreur est survenue lors de la suppression du compte.'
        });
    }
};
