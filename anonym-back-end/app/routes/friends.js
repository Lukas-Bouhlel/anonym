const express = require('express');
const router = express.Router();
const friendsCtrl = require('../controllers/friends');
const authMiddleware = require('../middlewares/auth');

router.get('/', authMiddleware, friendsCtrl.readAll);
router.get('/blocked', authMiddleware, friendsCtrl.readBlockedUsers);
router.get('/requests/incoming', authMiddleware, friendsCtrl.readIncomingRequests);
router.get('/requests/outgoing', authMiddleware, friendsCtrl.readOutgoingRequests);
router.get('/:id', authMiddleware, friendsCtrl.read);
router.post('/:username', authMiddleware, friendsCtrl.addFriend);
router.post('/:id/block', authMiddleware, friendsCtrl.blockUser);
router.delete('/:id/block', authMiddleware, friendsCtrl.unblockUser);

// Nouvelle route claire pour répondre à une demande reçue
router.put('/requests/:requestId/respond', authMiddleware, friendsCtrl.respondToRequest);
// Annuler une demande envoyée
router.delete('/requests/:requestId', authMiddleware, friendsCtrl.cancelOutgoingRequest);

// Compatibilité existante
router.put('/:id', authMiddleware, friendsCtrl.update);
router.delete('/:id', authMiddleware, friendsCtrl.delete);

module.exports = router;
