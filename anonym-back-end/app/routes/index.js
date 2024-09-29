const express = require('express')
const router = express();
const authRoutes = require('./auth.js');
const accountRoutes = require('./account.js');
const adminRoutes = require('./admin.js');
const shopRoutes = require('./shop.js');
const paymentRoutes = require('./payment.js');
const invoiceRoutes = require('./invoice.js');
const inventoryRoutes = require('./inventory.js');
const friendsRoutes = require('./friends.js');
const privateMessagesRoutes = require('./private_message.js');
const channelRoutes = require('./channel');

router.use("/auth", authRoutes);
router.use("/account", accountRoutes);
router.use("/admin", adminRoutes);
router.use("/shop", shopRoutes);
router.use("/payment", paymentRoutes);
router.use("/invoice", invoiceRoutes);
router.use("/inventory", inventoryRoutes);
router.use("/friends", friendsRoutes);
router.use("/privateMessage", privateMessagesRoutes);
router.use('/channels', channelRoutes);

module.exports = router