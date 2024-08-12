const express = require('express')
const router = express();
const authRoutes = require('./auth.js');
const accountRoutes = require('./account.js');

router.use("/auth", authRoutes);
router.use("/account", accountRoutes);

module.exports = router