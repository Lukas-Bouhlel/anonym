const express = require('express');
const router = express.Router();
const usersCtrl = require('../controllers/users.js');
const authMiddleware = require("../middlewares/auth.js");
const normalizeEmailMiddleware = require('../middlewares/normalizeEmail');

router.get('/users', authMiddleware, usersCtrl.readAll);
router.post('/users', authMiddleware, normalizeEmailMiddleware, usersCtrl.create);
router.put('/users/:id', authMiddleware, normalizeEmailMiddleware, usersCtrl.update);
router.delete('/users/:id', authMiddleware, usersCtrl.delete);

module.exports = router;