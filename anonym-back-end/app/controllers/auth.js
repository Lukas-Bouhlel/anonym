const { User, RegisterVerificationCode, RegisterVerificationEvent } = require('../models');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const fs = require('fs');
const path = require('path')
const { Op } = require('sequelize');
const CryptoJS = require('crypto-js');
const env = process.env.NODE_ENV || 'development';

const REGISTER_CODE_TTL_MINUTES = 10;
const REGISTER_RESEND_COOLDOWN_SECONDS = 60;
const REGISTER_SEND_WINDOW_MINUTES = 15;
const REGISTER_SEND_WINDOW_MAX = 5;
const REGISTER_VERIFY_MAX_ATTEMPTS = 5;
const REGISTER_VERIFY_BLOCK_MINUTES = 15;
const GENERIC_REGISTER_CODE_MESSAGE = 'Si votre email est valide, un code de verification vient d etre envoye.';

const normalizeEmail = (email) => {
    if (typeof email !== 'string') return '';
    const trimmed = email.trim().toLowerCase();
    const [localPart, domainPart] = trimmed.split('@');
    if (!localPart || !domainPart) return trimmed;
    if (domainPart === 'gmail.com') {
        return `${localPart.replace(/\./g, '')}@${domainPart}`;
    }
    return trimmed;
};

const hashOtpCode = (otpCode) => CryptoJS.SHA256(otpCode).toString();

const getRequesterIp = (req) => {
    if (req.ip) return String(req.ip);
    if (req.headers['x-forwarded-for']) {
        return String(req.headers['x-forwarded-for']).split(',')[0].trim();
    }
    return 'unknown';
};

const issueAuthResponse = (res, user) => {
    const token = jwt.sign(
        { userId: user.id, userRole: user.roles },
        process.env.JWT_SECRET,
        { expiresIn: '10h' }
    );

    res.cookie('token', token, {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'Strict',
        maxAge: 10 * 60 * 60 * 1000,
    });

    return res.status(200).json({ token, user });
};

/**
 * @module UserController
 */

/**
 * Inscrit un nouvel utilisateur et envoie un e-mail de confirmation.
 *
 * @function signup
 * @async
 * @param {Object} req - La requête HTTP.
 * @param {Object} res - La réponse HTTP.
 * @throws {Error} En cas d'erreur lors de la création de l'utilisateur ou de l'envoi de l'e-mail.
 *
 * @example
 * // Exemple de requête
 * POST /api/auth/signup
 * {
 *   "username": "nouvel_utilisateur",
 *   "email": "utilisateur@example.com",
 *   "password": "MotDePasse123!",
 *   "avatarData": {
 *     "circleColor": "#ff0000",
 *     "pathColor": "#00ff00",
 *     "uniqueAvatarName": "avatar.svg"
 *   }
 * }
 */
exports.signup = async (req, res) => {
    return res.status(410).json({
        message: "Cette route n'est plus disponible. Utilisez /auth/register/request-code puis /auth/register/confirm."
    });
};

/**
 * Authentifie un utilisateur et renvoie un token JWT.
 *
 * @function login
 * @async
 * @param {Object} req - La requête HTTP.
 * @param {Object} res - La réponse HTTP.
 * @throws {Error} En cas d'erreur d'authentification.
 *
 * @example
 * // Exemple de requête
 * POST /api/auth/login
 * {
 *   "identifier": "utilisateur@example.com",
 *   "password": "MotDePasse123!"
 * }
 */
exports.login = async (req, res) => {
    try {
        const { identifier, password } = req.body;

        // Vérifiez que le champ 'identifier' et le mot de passe sont fournis
        if (!identifier) {
            return res.status(400).json({ message: "Votre identifiant est requis." });
        }

        if (!password) {
            return res.status(400).json({ message: "Votre mot de passe est requis." });
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
            return res.status(404).json({ message: "Votre identifiant ou votre mot de passe est incorrect" });
        }

        // Comparer le mot de passe
        const passwordMatch = await bcrypt.compare(password, user.password);

        if (!passwordMatch) {
            return res.status(401).json({ message: "Votre identifiant ou votre mot de passe est incorrect" });
        }

        return issueAuthResponse(res, user);
    } catch (error) {
        res.status(500).json({
            message: error.message || 'An error occurred during login'
        });
    }
}

exports.requestRegisterCode = async (req, res) => {
    try {
        const email = normalizeEmail(req.body?.email);
        const ip = getRequesterIp(req);
        const now = new Date();

        if (!email) {
            return res.status(400).json({ message: 'Email requis.' });
        }

        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            return res.status(400).json({ message: 'Email invalide.' });
        }

        const windowStart = new Date(now.getTime() - REGISTER_SEND_WINDOW_MINUTES * 60 * 1000);

        const [emailWindowCount, ipWindowCount] = await Promise.all([
            RegisterVerificationEvent.count({
                where: {
                    email,
                    event_type: 'REQUEST_CODE',
                    createdAt: { [Op.gte]: windowStart }
                }
            }),
            RegisterVerificationEvent.count({
                where: {
                    ip,
                    event_type: 'REQUEST_CODE',
                    createdAt: { [Op.gte]: windowStart }
                }
            })
        ]);

        if (emailWindowCount >= REGISTER_SEND_WINDOW_MAX || ipWindowCount >= REGISTER_SEND_WINDOW_MAX) {
            console.warn(`[register_code] Rate limit hit email=${email} ip=${ip}`);
            return res.status(429).json({ message: 'Trop de tentatives. Reessayez plus tard.' });
        }

        const [existingUser, existingCode] = await Promise.all([
            User.findOne({ where: { email } }),
            RegisterVerificationCode.findOne({ where: { email } })
        ]);

        if (existingCode?.last_sent_at) {
            const elapsedMs = now.getTime() - new Date(existingCode.last_sent_at).getTime();
            if (elapsedMs < REGISTER_RESEND_COOLDOWN_SECONDS * 1000) {
                return res.status(429).json({ message: 'Attendez avant de redemander un code.' });
            }
        }

        await RegisterVerificationEvent.create({
            email,
            ip,
            event_type: 'REQUEST_CODE'
        });

        if (existingUser) {
            return res.status(200).json({ message: GENERIC_REGISTER_CODE_MESSAGE });
        }

        const otpCode = `${Math.floor(100000 + Math.random() * 900000)}`;
        const nextWindowStartedAt = existingCode?.send_window_started_at
            ? new Date(existingCode.send_window_started_at)
            : now;
        const isSameWindow = now.getTime() - nextWindowStartedAt.getTime() < REGISTER_SEND_WINDOW_MINUTES * 60 * 1000;
        const sendAttempts = isSameWindow ? (existingCode?.send_attempts || 0) + 1 : 1;

        if (sendAttempts > REGISTER_SEND_WINDOW_MAX) {
            return res.status(429).json({ message: 'Trop de tentatives. Reessayez plus tard.' });
        }

        const codeData = {
            email,
            code_hash: hashOtpCode(otpCode),
            code_expires_at: new Date(now.getTime() + REGISTER_CODE_TTL_MINUTES * 60 * 1000),
            last_sent_at: now,
            send_attempts: sendAttempts,
            send_window_started_at: isSameWindow ? nextWindowStartedAt : now,
            verify_attempts: 0,
            blocked_until: null,
            last_ip: ip
        };

        if (existingCode) {
            await existingCode.update(codeData);
        } else {
            await RegisterVerificationCode.create(codeData);
        }

        await req.mailer.sendEmail(
            email,
            'Votre code de verification Anonym',
            `Votre code de verification est ${otpCode}. Il expire dans ${REGISTER_CODE_TTL_MINUTES} minutes.`,
            `<p>Votre code de verification est <strong>${otpCode}</strong>.</p><p>Il expire dans ${REGISTER_CODE_TTL_MINUTES} minutes.</p>`
        );

        return res.status(200).json({ message: GENERIC_REGISTER_CODE_MESSAGE });
    } catch (error) {
        return res.status(500).json({ message: error.message || 'Erreur lors de la demande de code.' });
    }
};

exports.confirmRegisterCode = async (req, res) => {
    try {
        const email = normalizeEmail(req.body?.email);
        const { code, username, password } = req.body;
        const now = new Date();

        if (!email || !code || !username || !password) {
            return res.status(400).json({ message: 'Email, code, username et mot de passe sont requis.' });
        }

        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            return res.status(400).json({ message: 'Email invalide.' });
        }

        const otpEntry = await RegisterVerificationCode.findOne({ where: { email } });
        if (!otpEntry) {
            return res.status(400).json({ message: 'Code invalide ou expire.' });
        }

        if (otpEntry.blocked_until && new Date(otpEntry.blocked_until) > now) {
            return res.status(429).json({ message: 'Trop de tentatives de verification. Reessayez plus tard.' });
        }

        if (new Date(otpEntry.code_expires_at) <= now) {
            return res.status(400).json({ message: 'Code invalide ou expire.' });
        }

        if (otpEntry.code_hash !== hashOtpCode(String(code))) {
            const nextAttempts = (otpEntry.verify_attempts || 0) + 1;
            const updates = { verify_attempts: nextAttempts };
            if (nextAttempts >= REGISTER_VERIFY_MAX_ATTEMPTS) {
                updates.blocked_until = new Date(now.getTime() + REGISTER_VERIFY_BLOCK_MINUTES * 60 * 1000);
                console.warn(`[register_code] Verification blocked email=${email}`);
            }
            await otpEntry.update(updates);
            return res.status(400).json({ message: 'Code invalide ou expire.' });
        }

        const existingUser = await User.findOne({
            where: {
                [Op.or]: [{ email }, { username }]
            }
        });
        if (existingUser) {
            await otpEntry.destroy();
            return res.status(409).json({ message: 'Un compte existe deja avec ces informations.' });
        }

        const user = await User.create({
            username,
            email,
            password
        });

        if (!req.file && req.avatarData) {
            const { circleColor, pathColor, uniqueAvatarName } = req.avatarData;
            const defaultAvatarPath = path.join(__dirname, '../../uploads/profiles/default/default_avatar.svg');
            const userAvatarPath = path.resolve(__dirname, '../../uploads/profiles/avatars', uniqueAvatarName);

            if (fs.existsSync(defaultAvatarPath)) {
                let svgContent = fs.readFileSync(defaultAvatarPath, 'utf8');
                svgContent = svgContent
                    .replace(/<circle[^>]*fill="[^"]*"[^>]*>/, `<circle cx="115" cy="115" r="115" fill="${circleColor}"/>`)
                    .replace(/<path[^>]*fill="[^"]*"[^>]*>/, `<path d="M114.37 48L150.593 117.743L167.732 116.319L184.87 114.894L158.396 132.766C169.932 154.979 184.87 183.741 184.87 183.741L161.077 183.801L140.549 144.814L66.4727 183.801H44L54.9652 162.64L135.365 133.027C135.365 133.027 135.396 133.016 135.457 132.994C136.576 132.584 177.708 117.529 184.87 114.894L167.732 116.319L150.593 117.743L131.372 124.824L115.018 92.3567L103.054 114.894L89.6156 140.207L44 157.012L66.0193 141.308L79.1852 115.9L114.37 48Z" fill="${pathColor}"/>`);
                fs.writeFileSync(userAvatarPath, svgContent);
                user.avatar = `${req.protocol}://${req.get("host")}/uploads/profiles/avatars/${uniqueAvatarName}`;
                await user.save();
            }
        } else if (req.file) {
            user.avatar = `${req.protocol}://${req.get("host")}/uploads/profiles/avatars/${req.file.filename}`;
            await user.save();
        }

        await otpEntry.destroy();
        return issueAuthResponse(res, user);
    } catch (error) {
        if (error.name === 'SequelizeValidationError') {
            const messages = error.errors.map(err => err.message);
            return res.status(400).json({ message: messages });
        }
        return res.status(500).json({ message: error.message || 'Erreur lors de la confirmation de l inscription.' });
    }
};

/**
 * Déconnecte l'utilisateur en invalidant le cookie JWT.
 *
 * @function logout
 * @param {Object} req - La requête HTTP.
 * @param {Object} res - La réponse HTTP.
 * @throws {Error} En cas d'erreur lors de la déconnexion.
 *
 * @example
 * // Exemple de requête
 * POST /api/auth/logout
 */
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

/**
 * Demande une réinitialisation de mot de passe en envoyant un e-mail avec un lien de réinitialisation.
 *
 * @function requestPasswordReset
 * @async
 * @param {Object} req - La requête HTTP.
 * @param {Object} res - La réponse HTTP.
 * @throws {Error} En cas d'erreur lors de l'envoi de l'e-mail.
 *
 * @example
 * // Exemple de requête
 * POST /api/auth/request-password-reset
 * {
 *   "email": "utilisateur@example.com"
 * }
 */
exports.requestPasswordReset = async (req, res) => {
    try {
        const { email } = req.body;
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        
        if (!emailRegex.test(email)) {
            return res.status(400).json({ message: "L'adresse email fournie est invalide" });
        }

        const user = await User.findOne({ where: { email } });
 
        if (!user) {
            return res.status(404).json({ message: "Vous n'êtes pas inscrit sur la plateforme" });
        }

        // Générer un token unique
        const token = CryptoJS.lib.WordArray.random(20).toString();

        const hashedToken = CryptoJS.SHA256(token).toString();

        // Enregistrer le token haché et l'expiration (15 minutes)
        user.resetPasswordToken = hashedToken;
        user.resetPasswordExpires = Date.now() + 15 * 60 * 1000; // 15 minutes
        await user.save();

        // Créer un lien de réinitialisation
        const resetLink = `${env === 'production' ? process.env.ORIGIN_PROD : process.env.ORIGIN}/reset/?token=${token}`;

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

        res.status(200).json({ message: 'Email envoyé pour la réinitialisation de votre mot de passe' });
    } catch (error) {
        return res.status(500).json({ message: error.message || 'Impossible d’initier la réinitialisation du mot de passe' });
    }
};

/**
 * Réinitialise le mot de passe de l'utilisateur.
 *
 * @function resetPassword
 * @async
 * @param {Object} req - La requête HTTP.
 * @param {Object} res - La réponse HTTP.
 * @throws {Error} En cas d'erreur lors de la réinitialisation du mot de passe.
 *
 * @example
 * // Exemple de requête
 * POST /api/auth/reset-password?token=<TOKEN>
 * {
 *   "password": "NouveauMotDePasse123!",
 *   "confirmPassword": "NouveauMotDePasse123!"
 * }
 */
exports.resetPassword = async (req, res) => {
    try {
        const { token } = req.query;
        const { password, confirmPassword } = req.body;
    
        if (!password) {
            return res.status(400).json({ message: "Le mot de passe est requis" });
        }
    
        if (!confirmPassword) {
            return res.status(400).json({ message: "Le mot de passe de confirmation est requis" });
        }
    
        if (password !== confirmPassword) {
            return res.status(400).json({ message: "Les mots de passe ne correspondent pas" });
        }

        // Vérifier que le mot de passe respecte la regex définie dans le modèle
        const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+=\-[\]{};:,.<>?/\\|`~"'£¤§µ¢₹])[A-Za-z\d!@#$%^&*()_+=\-[\]{};:,.<>?/\\|`~"'£¤§µ¢₹]{12,}$/;
        if (!passwordRegex.test(password)) {
            return res.status(400).json({ 
                message: "Mot de passe : 12 caractères min, avec majuscules, minuscules, chiffres et caractères spéciaux"
            });
        }
        
        // Hacher le token fourni pour la comparaison
        const hashedToken = CryptoJS.SHA256(token).toString();

        const user = await User.findOne({
            where: {
                resetPasswordToken: hashedToken,
                resetPasswordExpires: { [Op.gt]: Date.now() } // Vérifier si le token est toujours valide
            }
        });

        if (!user) {
            return res.status(400).json({ message: "Votre session est invalide ou a expiré" });
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

        res.status(200).json({ message: 'Le mot de passe a été réinitialisé avec succès' });
    } catch (error) {
        res.status(500).json({ message: error.message || 'Impossible de réinitialiser le mot de passe' });
    }
};
