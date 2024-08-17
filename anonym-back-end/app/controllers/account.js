const { User } = require('../models');
const bcrypt = require('bcrypt');
const fs = require('fs');
const path = require('path');

exports.readAccount = async (req, res) => {
    try {
        const userId = req.auth.userId;// Récupérer l'ID de l'utilisateur depuis les paramètres JWT

        // Trouver l'utilisateur par ID avec findOne
        const user = await User.findOne({ where: { id: userId } });

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

exports.update = async (req, res) => {
    try {
        const userId = req.auth.userId;// Récupérer l'ID de l'utilisateur depuis les paramètres JWT
        const datas = JSON.parse(req.body.datas);
        const { username, email, password, avatar } = datas;

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
        if (username) user.username = username;
        if (email) user.email = email;
        if (password) user.password = await bcrypt.hash(password, 10);
        user.avatar = newAvatarPath;

        await user.save();

        res.status(200).json(user);
    } catch (error) {
        res.status(500).json({
            message: error.message || 'Une erreur est survenue lors de la mise à jour du compte.'
        });
    }
};

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

        // Supprimer l'avatar
        if (user.avatar) {
            const avatarPath = path.join(__dirname, '../../uploads/profiles/avatars', path.basename(user.avatar));
            fs.unlink(avatarPath, (err) => {
                if (err) {
                    console.error("Error deleting avatar file:", err);
                }
            });
        }

        // Supprimer l'utilisateur
        await user.destroy();

        res.status(200).json({ message: "User deleted successfully" });
    } catch (error) {
        res.status(500).json({
            message: error.message || 'Une erreur est survenue lors de la suppression du compte.'
        });
    }
};