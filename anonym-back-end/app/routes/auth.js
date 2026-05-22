const express = require('express');
const router = express();
const authCtrl = require("../controllers/auth.js");
const normalizeEmailMiddleware = require('../middlewares/normalizeEmail');
const multer = require('../middlewares/mutler.js');
const generateAvatar = require('../middlewares/generateAvatar');
const { requireCsrf } = require('../middlewares/csrf');

/**
 * @module routes/auth
 * @description Ce module gère les routes liées à l'authentification des utilisateurs, y compris l'inscription, la connexion, et la gestion des mots de passe.
 */
router.post("/signup", multer, generateAvatar, authCtrl.signup);
router.post('/register/request-code', multer, authCtrl.requestRegisterCode);
router.post('/register/confirm', multer, generateAvatar, authCtrl.confirmRegisterCode);
router.post('/login', requireCsrf, normalizeEmailMiddleware, authCtrl.login);
router.post('/refresh', requireCsrf, authCtrl.refreshToken);
router.post('/logout', requireCsrf, authCtrl.logout);
router.post('/reset-password', requireCsrf, normalizeEmailMiddleware, authCtrl.requestPasswordReset);
router.post('/reset/', requireCsrf, authCtrl.resetPassword);

module.exports = router;

