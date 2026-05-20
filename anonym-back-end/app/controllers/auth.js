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
const PASSWORD_REGEX = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+=\-[\]{};:,.<>?/\\|`~"'Â£Â¤Â§ÂµÂ¢â‚¹])[A-Za-z\d!@#$%^&*()_+=\-[\]{};:,.<>?/\\|`~"'Â£Â¤Â§ÂµÂ¢â‚¹]{12,}$/;

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

const normalizeUsername = (username) => {
    if (typeof username !== 'string') return '';
    return username.trim().toLowerCase();
};

const extractUsernameFromBody = (body) => {
    if (!body || typeof body !== 'object') return '';

    if (typeof body.username === 'string') return body.username;
    if (typeof body.userName === 'string') return body.userName;

    if (body.datas && typeof body.datas === 'object') {
        if (typeof body.datas.username === 'string') return body.datas.username;
        if (typeof body.datas.userName === 'string') return body.datas.userName;
    }

    if (typeof body.datas === 'string') {
        try {
            const parsedDatas = JSON.parse(body.datas);
            if (typeof parsedDatas?.username === 'string') return parsedDatas.username;
            if (typeof parsedDatas?.userName === 'string') return parsedDatas.userName;
        } catch {
            return '';
        }
    }

    return '';
};

const extractPasswordFromBody = (body) => {
    if (!body || typeof body !== 'object') return '';

    if (typeof body.password === 'string') return body.password;

    if (body.datas && typeof body.datas === 'object' && typeof body.datas.password === 'string') {
        return body.datas.password;
    }

    if (typeof body.datas === 'string') {
        try {
            const parsedDatas = JSON.parse(body.datas);
            if (typeof parsedDatas?.password === 'string') return parsedDatas.password;
        } catch {
            return '';
        }
    }

    return '';
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

const getRuntimeEnvVar = (baseName) => {
    if (env === 'production') {
        return process.env[`${baseName}_PROD`] || process.env[baseName];
    }
    if (env === 'preprod') {
        return process.env[`${baseName}_PREPROD`] || process.env[baseName];
    }
    return process.env[baseName];
};

const buildResetPasswordLink = (baseUrl, token) => {
    if (typeof baseUrl !== 'string') return '';
    const trimmedBaseUrl = baseUrl.trim();
    if (!trimmedBaseUrl) return '';

    const encodedToken = encodeURIComponent(token);

    // Allows templates like "myapp://reset?token={token}" or "https://my.app/reset/{token}"
    if (trimmedBaseUrl.includes('{token}')) {
        return trimmedBaseUrl.replace('{token}', encodedToken);
    }

    const withoutTrailingSlash = trimmedBaseUrl.replace(/\/+$/, '');
    const hasResetPath = /\/reset\/?(\?|$)/i.test(withoutTrailingSlash);
    const urlWithResetPath = hasResetPath ? withoutTrailingSlash : `${withoutTrailingSlash}/reset/`;
    const separator = urlWithResetPath.includes('?') ? '&' : '?';

    return `${urlWithResetPath}${separator}token=${encodedToken}`;
};

const isHttpLink = (url) => {
    if (typeof url !== 'string') return false;
    return /^https?:\/\//i.test(url.trim());
};

const getResetPasswordWebBaseUrl = () => {
    return getRuntimeEnvVar('RESET_PASSWORD_WEB_URL')
        || getRuntimeEnvVar('RESET_PASSWORD_URL')
        || getRuntimeEnvVar('ORIGIN');
};

const getResetPasswordMobileBaseUrl = () => getRuntimeEnvVar('RESET_PASSWORD_MOBILE_URL');

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
        const username = normalizeUsername(extractUsernameFromBody(req.body));
        const password = extractPasswordFromBody(req.body);
        const ip = getRequesterIp(req);
        const now = new Date();

        if (!email) {
            return res.status(400).json({ message: 'Email requis.' });
        }

        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            return res.status(400).json({ message: 'Email invalide.' });
        }

        if (!username) {
            return res.status(400).json({ message: "Le nom d'utilisateur est requis." });
        }
        if (!password) {
            return res.status(400).json({ message: 'Le mot de passe est requis.' });
        }
        if (!PASSWORD_REGEX.test(password)) {
            return res.status(400).json({
                message: "Mot de passe : 12 caractères min, avec majuscules, minuscules, chiffres et caractères spéciaux"
            });
        }

        const [existingUsernameUser, existingEmailUser] = await Promise.all([
            User.findOne({
                where: User.sequelize.where(
                    User.sequelize.fn('LOWER', User.sequelize.col('username')),
                    username
                )
            }),
            User.findOne({ where: { email } })
        ]);

        if (existingUsernameUser) {
            return res.status(409).json({ message: "Ce nom d'utilisateur est deja utilise." });
        }
        if (existingEmailUser) {
            return res.status(409).json({ message: "L'adresse email est deja utilise." });
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

        const existingCode = await RegisterVerificationCode.findOne({ where: { email } });

        if (existingCode?.last_sent_at) {
            const elapsedMs = now.getTime() - new Date(existingCode.last_sent_at).getTime();
            if (elapsedMs < REGISTER_RESEND_COOLDOWN_SECONDS * 1000) {
                const remainingSeconds = Math.ceil((REGISTER_RESEND_COOLDOWN_SECONDS * 1000 - elapsedMs) / 1000);
                return res.status(429).json({
                    message: `Veuillez patienter ${remainingSeconds}s avant de redemander un code.`,
                    retry_after_seconds: remainingSeconds
                });
            }
        }

        await RegisterVerificationEvent.destroy({ where: { email } });
        await RegisterVerificationEvent.create({
            email,
            ip,
            event_type: 'REQUEST_CODE'
        });

        const otpCode = `${Math.floor(100000 + Math.random() * 900000)}`;
        const pendingPasswordHash = await bcrypt.hash(password, 10);
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
            pending_username: username,
            pending_password_hash: pendingPasswordHash,
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

        return res.status(200).json({
            message: 'Code de verification renvoye avec succes.',
            code_resent: true
        });
    } catch (error) {
        return res.status(500).json({ message: error.message || 'Erreur lors de la demande de code.' });
    }
};

exports.confirmRegisterCode = async (req, res) => {
    try {
        const email = normalizeEmail(req.body?.email);
        const { code } = req.body;
        const now = new Date();

        if (!email || !code) {
            return res.status(400).json({ message: 'Email et code sont requis.' });
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

        const username = normalizeUsername(otpEntry.pending_username);
        const pendingPasswordHash = otpEntry.pending_password_hash;
        if (!username || !pendingPasswordHash) {
            return res.status(400).json({ message: 'Informations de pre-inscription manquantes. Redemandez un code.' });
        }

        const [existingEmailUser, existingUsernameUser] = await Promise.all([
            User.findOne({ where: { email } }),
            User.findOne({
                where: User.sequelize.where(
                    User.sequelize.fn('LOWER', User.sequelize.col('username')),
                    username
                )
            })
        ]);

        if (existingEmailUser) {
            await RegisterVerificationCode.destroy({ where: { email } });
            await RegisterVerificationEvent.destroy({ where: { email } });
            return res.status(409).json({ message: 'Un compte existe deja avec cet email.' });
        }

        if (existingUsernameUser) {
            return res.status(409).json({ message: "Ce nom d'utilisateur est deja utilise." });
        }

        let newAvatarPath = null;
        if (!req.file && req.avatarData) {
            const { circleColor, pathColor, uniqueAvatarName } = req.avatarData;
            const defaultAvatarPath = path.join(__dirname, '../../uploads/profiles/default/default_avatar.svg');
            const userAvatarPath = path.resolve(__dirname, '../../uploads/profiles/avatars', uniqueAvatarName);

            let svgContent = fs.readFileSync(defaultAvatarPath, 'utf8');
            svgContent = svgContent.replace(/<circle[^>]*fill="[^"]*"[^>]*>/, `<circle cx="115" cy="115" r="115" fill="${circleColor}"/>`);
            svgContent = svgContent.replace(/<path[^>]*fill="[^"]*"[^>]*>/, `<path d="M114.37 48L150.593 117.743L167.732 116.319L184.87 114.894L158.396 132.766C169.932 154.979 184.87 183.741 184.87 183.741L161.077 183.801L140.549 144.814L66.4727 183.801H44L54.9652 162.64L135.365 133.027C135.365 133.027 135.396 133.016 135.457 132.994C136.576 132.584 177.708 117.529 184.87 114.894L167.732 116.319L150.593 117.743L131.372 124.824L115.018 92.3567L103.054 114.894L89.6156 140.207L44 157.012L66.0193 141.308L79.1852 115.9L114.37 48Z" fill="${pathColor}"/>`);
            fs.writeFileSync(userAvatarPath, svgContent);
            newAvatarPath = `${req.protocol}://${req.get('host')}/uploads/profiles/avatars/${uniqueAvatarName}`;
        } else if (req.file) {
            newAvatarPath = `${req.protocol}://${req.get('host')}/uploads/profiles/avatars/${req.file.filename}`;
        }

        const user = await User.create({
            username,
            email,
            password: pendingPasswordHash,
            avatar: newAvatarPath
        }, { hooks: false, validate: false });

        await RegisterVerificationCode.destroy({ where: { email } });
        await RegisterVerificationEvent.destroy({ where: { email } });
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
        const webResetLink = buildResetPasswordLink(getResetPasswordWebBaseUrl(), token);
        if (!webResetLink) {
            return res.status(500).json({ message: "Configuration manquante pour l'URL de reinitialisation web" });
        }
        const mobileResetLink = buildResetPasswordLink(getResetPasswordMobileBaseUrl(), token);
        // Beaucoup de clients e-mail bloquent les schemes custom (ex: anonym://),
        // donc on garde un bouton cliquable en privilégiant HTTP(S).
        const primaryResetLink = isHttpLink(mobileResetLink) ? mobileResetLink : webResetLink;
        // Lire le template d'email
        const emailTemplatePath = path.join(__dirname, '../../templates/reset-password-email.html');
        let htmlContent = fs.readFileSync(emailTemplatePath, 'utf8');
        htmlContent = htmlContent.replace(/{{resetLink}}/g, primaryResetLink);
        htmlContent = htmlContent.replace(/{{resetFallbackLink}}/g, webResetLink);

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
        const token = req.query?.token || req.body?.token;
        const { password, confirmPassword } = req.body;

        if (!token) {
            return res.status(400).json({ message: 'Le token de reinitialisation est requis' });
        }
    
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

