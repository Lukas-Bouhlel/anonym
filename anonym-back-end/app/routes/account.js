const express = require('express');
const router = express();
const accountCtrl = require("../controllers/account.js");
const normalizeEmailMiddleware = require('../middlewares/normalizeEmail');
const authMiddleware = require("../middlewares/auth.js");
const authorizeAdminMiddleware = require("../middlewares/authorizeAdmin.js");
const generateAvatar = require('../middlewares/generateAvatar');
const multer = require('../middlewares/mutler.js');

/**
 * @module routes/account
 * @description Ce module gère les routes relatives aux comptes utilisateurs, y compris la lecture, la mise à jour, et la suppression de comptes.
 */
router.get("/", authMiddleware, accountCtrl.readAccount);
router.get('/discoverable-users', authMiddleware, accountCtrl.readDiscoverable);
router.get('/users', authMiddleware, authorizeAdminMiddleware, accountCtrl.readAll);
router.put("/update", authMiddleware, normalizeEmailMiddleware, multer, generateAvatar, accountCtrl.update);
router.patch('/presence', authMiddleware, accountCtrl.updatePresence);
router.post('/push-token', authMiddleware, accountCtrl.upsertPushToken);
router.delete('/push-token', authMiddleware, accountCtrl.deletePushToken);
router.delete("/delete", authMiddleware, accountCtrl.delete);
router.get("/:id", authMiddleware, accountCtrl.read);
router.put('/password', authMiddleware, accountCtrl.updatePassword);

module.exports = router;
