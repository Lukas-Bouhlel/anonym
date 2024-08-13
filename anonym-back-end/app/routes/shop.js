const express = require('express');
const router = express.Router();
const shopCtrl = require('../controllers/shop.js');
const authMiddleware = require("../middlewares/auth.js");

router.get('/', authMiddleware, shopCtrl.readAll);
router.get('/:id', authMiddleware, shopCtrl.read);
router.post('/', authMiddleware, shopCtrl.create);
router.put('/:id', authMiddleware, shopCtrl.update);
router.delete('/:id', authMiddleware, shopCtrl.delete);
router.get('/:id/payment', authMiddleware, shopCtrl.payment);

module.exports = router;