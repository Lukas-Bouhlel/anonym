const { User } = require('../models');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const fs = require('fs');
const path = require('path')
const { Op } = require('sequelize');
const crypto = require('crypto');

exports.signup = async (req, res) => {
    try {

        // Créer l'utilisateur avec l'avatar (soit celui téléchargé, soit la copie du défaut)
        const user = await User.create({
            ...req.body
        });

        // Après la création réussie de l'utilisateur, générer l'avatar si nécessaire
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
            user.avatar = `${req.protocol}://${req.get("host")}/uploads/profiles/avatars/${uniqueAvatarName}`;
            await user.save();
        }

         // Lire le fichier HTML pour l'e-mail
        const emailTemplatePath = path.join(__dirname, '../../templates/signup-email.html');
        let htmlContent = fs.readFileSync(emailTemplatePath, 'utf8');

        // Remplacer le nom de l'utilisateur dans le contenu HTML
        htmlContent = htmlContent.replace(/Salut\s+Rei,/, `Salut ${user.username},`);

        // Envoyer l'e-mail de confirmation avec le contenu HTML
        await req.mailer.sendEmail(
            user.email,// Destinataire
            'Bienvenue sur notre plateforme Anonym !',// Sujet
            '',// Contenu texte (vide)
            htmlContent// Contenu HTML
        );


        res.status(201).json(user);
    } catch (error) {
        res.status(500).json({
            message: error.message || 'Could not create user'
        });
    }
}

exports.login = async (req, res) => {
    try {
        const { identifier, password } = req.body;

        // Vérifiez que le champ 'identifier' et le mot de passe sont fournis
        if (!identifier || !password) {
            return res.status(400).json({ message: "Identifier and password are required." });
        }

        // Chercher l'utilisateur par email ou nom d'utilisateur
        const user = await User.findOne({
            where: {
                [Op.or]: [
                    { email: identifier },
                    { username: identifier }
                ]
            }
        });

        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        // Comparer le mot de passe
        const passwordMatch = await bcrypt.compare(password, user.password);

        if (!passwordMatch) {
            return res.status(401).json({ message: "Invalid password" });
        }

        // Générer le token JWT
        const token = jwt.sign(
            { userId: user.id, userRole: user.roles }, 
            process.env.JWT_SECRET, 
            { expiresIn: '10h' }
        );

        res.cookie('token', token, {
            httpOnly: true,  // Empêche l'accès au cookie via JS
            secure: process.env.NODE_ENV === 'production',  // Seulement en HTTPS en production
            sameSite: 'Strict',  // Empêche l'envoi du cookie pour les requêtes cross-site
            maxAge: 10 * 60 * 60 * 1000,  // Expire dans 10 heures
        });

        res.status(200).json({ token, user });
    } catch (error) {
        res.status(500).json({
            message: error.message || 'An error occurred during login'
        });
    }
}

exports.logout = (req, res) => {
    try {
        // Invalider le cookie contenant le token JWT
        res.clearCookie('token', {
            httpOnly: true,
            secure: process.env.NODE_ENV === 'production',
            sameSite: 'Strict',
        });

        // Envoyer une réponse de succès
        res.status(200).json({ message: "Successfully logged out" });
    } catch (error) {
        res.status(500).json({ message: error.message || 'Logout failed' });
    }
};

exports.requestPasswordReset = async (req, res) => {
    const { email } = req.body;

    try {
        const user = await User.findOne({ where: { email } });
        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        // Générer un token unique
        const token = crypto.randomBytes(20).toString('hex');

        // Enregistrer le token et l'expiration (15 minutes)
        user.resetPasswordToken = token;
        user.resetPasswordExpires = Date.now() + 15 * 60 * 1000; // 15 minutes
        await user.save();

        // Créer un lien de réinitialisation
        const resetLink = `${process.env.ORIGIN}/reset/?token=${token}`;

        // Lire le template d'email
        const emailTemplatePath = path.join(__dirname, '../../templates/reset-password-email.html');
        let htmlContent = fs.readFileSync(emailTemplatePath, 'utf8');
        htmlContent = htmlContent.replace(/{{resetLink}}/, resetLink);

        // Envoyer l'email
        await req.mailer.sendEmail(
            user.email,
            'Réinitialisation de votre mot de passe',
            '',
            htmlContent
        );

        res.status(200).json({ message: 'Email sent for password reset' });
    } catch (error) {
        res.status(500).json({ message: error.message || 'Could not initiate password reset' });
    }
};

exports.resetPassword = async (req, res) => {
    const { token } = req.query;
    const { password, confirmPassword } = req.body;

    try {
        const user = await User.findOne({
            where: {
                resetPasswordToken: token,
                resetPasswordExpires: { [Op.gt]: Date.now() } // Vérifier si le token est toujours valide
            }
        });

        if (!user) {
            return res.status(400).json({ message: "Token is invalid or has expired" });
        }

        if (password !== confirmPassword) {
            return res.status(400).json({ message: "Passwords do not match" });
        }

        // Hash le nouveau mot de passe
        user.password = await bcrypt.hash(password, 10);
        user.resetPasswordToken = null; // Réinitialiser le token
        user.resetPasswordExpires = null; // Réinitialiser l'expiration
        await user.save();

        // Envoyer un email de confirmation
        const confirmationEmailTemplatePath = path.join(__dirname, '../../templates/reset-password-confirmation-email.html');
        let confirmationHtmlContent = fs.readFileSync(confirmationEmailTemplatePath, 'utf8');
        confirmationHtmlContent = confirmationHtmlContent.replace(/{{username}}/, user.username);

        await req.mailer.sendEmail(
            user.email,
            'Votre mot de passe a été réinitialisé',
            '',
            confirmationHtmlContent
        );

        // Invalider le cookie contenant le token JWT
        res.clearCookie('token', {
            httpOnly: true,
            secure: process.env.NODE_ENV === 'production',
            sameSite: 'Strict',
        });

        res.status(200).json({ message: 'Password has been reset successfully' });
    } catch (error) {
        res.status(500).json({ message: error.message || 'Could not reset password' });
    }
};