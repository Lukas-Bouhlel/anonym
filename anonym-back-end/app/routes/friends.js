const express = require('express');
const router = express.Router();
const friendsCtrl = require('../controllers/friends');
const authMiddleware = require('../middlewares/auth');

router.get('/', authMiddleware, friendsCtrl.readAll);
router.get('/:id', authMiddleware, friendsCtrl.read);
router.post('/:id', authMiddleware, friendsCtrl.addFriend);
router.put('/:id', authMiddleware, friendsCtrl.update);
router.delete('/:id', authMiddleware, friendsCtrl.delete);

module.exports = router;