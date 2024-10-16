const express = require('express');
const router = express.Router();
const inventoryCtrl = require('../controllers/inventory.js');
const authMiddleware = require('../middlewares/auth');
/**
 * @module routes/inventory
 * @description Ce module gère les routes relatives à l'inventaire de l'utilisateur, y compris la lecture, la mise à jour.
 */
router.get('/:item_id', authMiddleware, inventoryCtrl.read); // Lire un article spécifique dans l'inventaire d'un utilisateur
router.get('/', authMiddleware, inventoryCtrl.readAll); // Lire tous les articles dans l'inventaire d'un utilisateur
router.put('/:item_id', authMiddleware, inventoryCtrl.updateStatus);

/**
 * @module routes/admin/inventory
 * @description Ce module pour les admins gère les routes relatives à l'inventaire de tout les utilisateurs et la gestion des articles.
 */
router.post('/admin/', authMiddleware, inventoryCtrl.create);
router.put('/admin/:item_id', authMiddleware, inventoryCtrl.update);
router.delete('/admin/:item_id', authMiddleware, inventoryCtrl.delete);
router.get('/admin/inventories', authMiddleware, inventoryCtrl.adminReadAll); // Lire tous les articles de tous les utilisateurs

module.exports = router;
