const express = require('express');
const router = express.Router();
const privateMessagesCtrl = require('../controllers/private_message.js');
const authMiddleware = require('../middlewares/auth');

router.put('/:message_id', authMiddleware, privateMessagesCtrl.update); // Mettre à jour un message
router.delete('/:message_id', authMiddleware, privateMessagesCtrl.delete); // Supprimer un message

module.exports = router;