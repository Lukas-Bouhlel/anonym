const express = require('express');
const router = express.Router();
const usersCtrl = require('../controllers/users.js');
const authMiddleware = require("../middlewares/auth.js");

router.get('/users', authMiddleware, usersCtrl.readAll);
router.put('/users/:id', authMiddleware, usersCtrl.update);
router.delete('/users/:id', authMiddleware, usersCtrl.delete);

module.exports = router;