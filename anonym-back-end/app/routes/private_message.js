const express = require('express');
const router = express.Router();
const privateMessagesCtrl = require('../controllers/private_message.js');
const authMiddleware = require('../middlewares/auth');
const messageImageMulter = require('../middlewares/messageImageMulter.js');

/**
 * @module routes/privateMessage
 * @description Ce module gère les routes relatives aux messages privés, y compris la mise à jour et la suppression des messages.
 */
router.post('/upload', authMiddleware, messageImageMulter, privateMessagesCtrl.uploadImage); // Upload une image
router.put('/:message_id', authMiddleware, privateMessagesCtrl.update); // Mettre à jour un message
router.delete('/:message_id', authMiddleware, privateMessagesCtrl.delete); // Supprimer un message

module.exports = router;