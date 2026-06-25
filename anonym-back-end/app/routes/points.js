const express = require('express');
const router = express.Router();
const authMiddleware = require('../middlewares/auth');
const pointsCtrl = require('../controllers/points');

router.get('/me', authMiddleware, pointsCtrl.getMyPointsStats);

module.exports = router;
