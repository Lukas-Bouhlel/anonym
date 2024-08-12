const express = require('express');
const router = express();
const accountCtrl = require("../controllers/account.js");
const normalizeEmailMiddleware = require('../middlewares/normalizeEmail');
const authMiddleware = require("../middlewares/auth.js");

router.get("/", authMiddleware, accountCtrl.read);
router.put("/update", authMiddleware, normalizeEmailMiddleware, accountCtrl.update);
router.delete("/delete", authMiddleware, accountCtrl.delete);

module.exports = router;