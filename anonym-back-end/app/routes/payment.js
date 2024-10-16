const express = require('express');
const router = express.Router();
const paymentCtrl = require('../controllers/payment.js');
const authMiddleware = require("../middlewares/auth.js");

/**
 * @module routes/payment
 * @description Ce module gère les routes relatives aux paiements, y compris la création de paiements et la confirmation de paiements.
 */
router.post('/', authMiddleware, paymentCtrl.create);
router.get('/confirm', paymentCtrl.success);

module.exports = router;