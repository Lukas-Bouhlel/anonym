const express = require('express');
const router = express.Router();
const inventoryCtrl = require('../controllers/inventory.js');
const authMiddleware = require('../middlewares/auth');

// Routes pour les utilisateurs
router.get('/:item_id', authMiddleware, inventoryCtrl.read); // Lire un article spécifique dans l'inventaire d'un utilisateur
router.get('/', authMiddleware, inventoryCtrl.readAll); // Lire tous les articles dans l'inventaire d'un utilisateur

// Routes pour les admins
router.post('/admin/', authMiddleware, inventoryCtrl.create);
router.put('/admin/:item_id', authMiddleware, inventoryCtrl.update);
router.delete('/admin/:item_id', authMiddleware, inventoryCtrl.delete);
router.get('/admin/inventories', authMiddleware, inventoryCtrl.adminReadAll); // Lire tous les articles de tous les utilisateurs

module.exports = router;
