const express = require('express');
const router = express.Router();
const usersCtrl = require('../controllers/users.js');
const authMiddleware = require("../middlewares/auth.js");
const normalizeEmailMiddleware = require('../middlewares/normalizeEmail');
const mutler = require('../middlewares/mutler.js');
const generateAvatar = require('../middlewares/generateAvatar');

router.post('/users', authMiddleware, normalizeEmailMiddleware, mutler, generateAvatar, usersCtrl.create);
router.put('/users/:id', authMiddleware, normalizeEmailMiddleware, mutler, generateAvatar, usersCtrl.update);
router.delete('/users/:id', authMiddleware, usersCtrl.delete);
router.post('/report',  normalizeEmailMiddleware, usersCtrl.report)

module.exports = router;