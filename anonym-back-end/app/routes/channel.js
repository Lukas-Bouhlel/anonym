const express = require('express');
const router = express.Router();
const channelCtrl = require('../controllers/channel.js');
const authMiddleware = require('../middlewares/auth');

router.post('/', authMiddleware, channelCtrl.create);
router.post('/invite', authMiddleware, channelCtrl.invite);
router.get('/user', authMiddleware, channelCtrl.getUserChannels);
router.get('/:id/unreadCount', authMiddleware, channelCtrl.getUnreadMessageCount);
router.get('/:id/users', authMiddleware, channelCtrl.getChannelUsers);
router.get('/:id/messages', authMiddleware, channelCtrl.getChannelMessages);
router.delete('/leave/:id', authMiddleware, channelCtrl.leaveChannel);
router.delete('/:id', authMiddleware, channelCtrl.deleteChannel);

module.exports = router;