const express = require('express');
const router = express();
const authCtrl = require("../controllers/auth.js");
const normalizeEmailMiddleware = require('../middlewares/normalizeEmail');
const multer = require('../middlewares/mutler.js');
const generateAvatar = require('../middlewares/generateAvatar');

router.post("/signup", multer, generateAvatar, authCtrl.signup);
router.post("/login", normalizeEmailMiddleware, authCtrl.login);
router.post("/logout", authCtrl.logout);

module.exports = router;