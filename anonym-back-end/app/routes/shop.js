const express = require('express');
const router = express.Router();
const shopCtrl = require('../controllers/shop.js');
const authMiddleware = require("../middlewares/auth.js");
const multer = require('../middlewares/mutler.js')

/**
 * @module routes/shop
 * @description Ce module gère les routes relatives à la boutique.
 */
router.get('/', authMiddleware, shopCtrl.readAll);
router.get('/:id', authMiddleware, shopCtrl.read);

/**
 * @module routes/admin/shop
 * @description Ce module gère les routes relatives à la boutique pour les admins, y compris la lecture, la création, la mise à jour et la suppression des articles.
 */
router.post('/admin/', authMiddleware, multer, shopCtrl.create);
router.put('/admin/:id', authMiddleware, multer, shopCtrl.update);
router.delete('/admin/:id', authMiddleware, multer, shopCtrl.delete);

module.exports = router;