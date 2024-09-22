const express = require('express');
const router = express.Router();
const paymentCtrl = require('../controllers/payment.js');
const authMiddleware = require("../middlewares/auth.js");

router.post('/', authMiddleware, paymentCtrl.create);
router.get('/confirm', paymentCtrl.success);

module.exports = router;