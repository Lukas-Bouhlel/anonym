const express = require('express');
const router = express();
const userCtrl = require("../controllers/auth.js");
const normalizeEmail = require('../middlewares/normalizeEmail');

router.get("/", userCtrl.base);
router.post("/signup", userCtrl.signup);
router.post("/login", normalizeEmail, userCtrl.login);

module.exports = router;