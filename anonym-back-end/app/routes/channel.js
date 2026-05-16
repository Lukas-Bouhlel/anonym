const express = require('express');
const router = express.Router();
const channelCtrl = require('../controllers/channel.js');
const authMiddleware = require('../middlewares/auth');
const channelMulter = require('../middlewares/channelMulter.js');

/**
 * @module routes/channel
 * @description Ce module gère les routes liées aux canaux, y compris la création, l'invitation d'utilisateurs, et la gestion des messages.
 */
router.post('/', authMiddleware, channelMulter, channelCtrl.create);
router.post('/invite', authMiddleware, channelCtrl.invite);
router.put('/:id', authMiddleware, channelCtrl.updateChannel);
router.put('/:id/cover', authMiddleware, channelMulter, channelCtrl.updateCoverImage);
router.post('/:id/invite-links', authMiddleware, channelCtrl.createInviteLink);
router.post('/:id/join-public', authMiddleware, channelCtrl.joinPublicChannel);
router.post('/join-by-invite', authMiddleware, channelCtrl.joinByInviteCode);
router.get('/user', authMiddleware, channelCtrl.getUserChannels);
router.get('/:id/unreadCount', authMiddleware, channelCtrl.getUnreadMessageCount);
router.get('/:id/users', authMiddleware, channelCtrl.getChannelUsers);
router.get('/:id/messages', authMiddleware, channelCtrl.getChannelMessages);
router.delete('/leave/:id', authMiddleware, channelCtrl.leaveChannel);
router.delete('/:id', authMiddleware, channelCtrl.deleteChannel);

module.exports = router;
