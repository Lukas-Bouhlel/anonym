const express = require('express');
const router = express();
const accountCtrl = require("../controllers/account.js");
const normalizeEmailMiddleware = require('../middlewares/normalizeEmail');
const authMiddleware = require("../middlewares/auth.js");
const generateAvatar = require('../middlewares/generateAvatar');
const multer = require('../middlewares/mutler.js');

router.get("/", authMiddleware, accountCtrl.read);
router.put("/update", authMiddleware, normalizeEmailMiddleware, multer, generateAvatar, accountCtrl.update);
router.delete("/delete", authMiddleware, accountCtrl.delete);

module.exports = router;