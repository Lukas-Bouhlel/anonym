const express = require('express')
const router = express();
const authRoutes = require('./auth.js');
const accountRoutes = require('./account.js');
const adminRoutes = require('./admin.js');
const shopRoutes = require('./shop.js');

router.use("/auth", authRoutes);
router.use("/account", accountRoutes);
router.use("/admin", adminRoutes);
router.use("/shop", shopRoutes);

module.exports = router