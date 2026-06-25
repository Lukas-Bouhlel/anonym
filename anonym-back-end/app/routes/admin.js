const express = require('express');
const router = express.Router();
const swaggerUi = require('swagger-ui-express');
const fs = require("fs");
const YAML = require('yaml');
const file  = fs.readFileSync('./app/utils/swagger.yaml', 'utf8');
const swaggerDocument = YAML.parse(file);
const usersCtrl = require('../controllers/users.js');
const accountCtrl = require('../controllers/account.js');
const authCtrl = require('../controllers/auth.js');
const authMiddleware = require("../middlewares/auth.js");
const normalizeEmailMiddleware = require('../middlewares/normalizeEmail');
const mutler = require('../middlewares/mutler.js');
const generateAvatar = require('../middlewares/generateAvatar');
const authorizeAdminMiddleware = require("../middlewares/authorizeAdmin.js"); // Importez le middleware d'autorisation
const { requireCsrf } = require('../middlewares/csrf');

/**
 * @module routes/account
 * @description Ce module gère les routes relatives aux comptes utilisateurs, y compris la lecture, la mise à jour, et la suppression de comptes.
 */
router.post('/login', requireCsrf, normalizeEmailMiddleware, authCtrl.loginAdmin);
router.get('/users', authMiddleware, authorizeAdminMiddleware, accountCtrl.readAll);
router.post('/users', authMiddleware, authorizeAdminMiddleware, normalizeEmailMiddleware, mutler, generateAvatar, usersCtrl.create);
router.put('/users/:id', authMiddleware, authorizeAdminMiddleware, normalizeEmailMiddleware, mutler, generateAvatar, usersCtrl.update);
router.delete('/users/:id', authMiddleware, authorizeAdminMiddleware, usersCtrl.delete);
router.post('/report',  normalizeEmailMiddleware, usersCtrl.report)
router.use('/api-docs', authMiddleware, authorizeAdminMiddleware, swaggerUi.serve, swaggerUi.setup(swaggerDocument));

module.exports = router;
