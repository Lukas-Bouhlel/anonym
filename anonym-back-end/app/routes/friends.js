const express = require('express');
const router = express.Router();
const friendsCtrl = require('../controllers/friends');
const authMiddleware = require('../middlewares/auth');

/**
 * @module routes/friends
 * @description Ce module gère les routes relatives à la gestion des amis, y compris l'ajout, la mise à jour et la suppression d'amis.
 */
router.get('/', authMiddleware, friendsCtrl.readAll);
router.get('/:id', authMiddleware, friendsCtrl.read);
router.post('/:username', authMiddleware, friendsCtrl.addFriend);
router.put('/:id', authMiddleware, friendsCtrl.update);
router.delete('/:id', authMiddleware, friendsCtrl.delete);

module.exports = router;