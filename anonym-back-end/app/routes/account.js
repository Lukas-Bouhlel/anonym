const express = require('express');
const router = express();
const accountCtrl = require("../controllers/account.js");
const normalizeEmail = require('../middlewares/normalizeEmail');
const auth = require("../middlewares/auth.js");

router.get("/", auth, accountCtrl.read);
router.get("/update", auth, normalizeEmail, accountCtrl.update);
router.get("/delete", auth, accountCtrl.delete);

module.exports = router;