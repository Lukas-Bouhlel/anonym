const express = require('express');
const router = express();
const userCtrl = require("../controllers/auth.js");

router.get("/", userCtrl.base);
router.post("/signup", userCtrl.signup);
router.post("/login", userCtrl.login);

module.exports = router;