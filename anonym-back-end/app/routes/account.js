const express = require('express');
const router = express();
const accountCtrl = require("../controllers/account.js");
const auth = require("../middlewares/auth.js");

router.get("/", auth, accountCtrl.read);
router.get("/update", auth, accountCtrl.update);
router.get("/delete", auth, accountCtrl.delete);

module.exports = router;