const express = require('express');
const router = express.Router();
const paymentCtrl = require('../controllers/payment.js');
const authMiddleware = require("../middlewares/auth.js");

router.post('/', authMiddleware, paymentCtrl.create);

module.exports = router;