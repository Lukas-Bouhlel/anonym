const express = require('express');
const router = express();
const authCtrl = require("../controllers/auth.js");
const normalizeEmailMiddleware = require('../middlewares/normalizeEmail');
const multer = require('../middlewares/mutler.js');
const generateAvatar = require('../middlewares/generateAvatar');

/**
 * @module routes/auth
 * @description Ce module gère les routes liées à l'authentification des utilisateurs, y compris l'inscription, la connexion, et la gestion des mots de passe.
 */
router.post("/signup", multer, generateAvatar, authCtrl.signup);
router.post("/login", normalizeEmailMiddleware, authCtrl.login);
router.post("/logout", authCtrl.logout);
router.post('/reset-password', normalizeEmailMiddleware, authCtrl.requestPasswordReset);
router.post('/reset/', authCtrl.resetPassword);

module.exports = router;