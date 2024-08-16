const express = require('express');
const router = express.Router();
const shopCtrl = require('../controllers/shop.js');
const authMiddleware = require("../middlewares/auth.js");
const multer = require('../middlewares/mutler.js')

router.get('/', authMiddleware, shopCtrl.readAll);
router.get('/:id', authMiddleware, shopCtrl.read);
router.post('/', authMiddleware, multer, shopCtrl.create);
router.put('/:id', authMiddleware, multer, shopCtrl.update);
router.delete('/:id', authMiddleware, multer, shopCtrl.delete);

module.exports = router;