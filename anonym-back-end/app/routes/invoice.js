const express = require('express');
const router = express.Router();
const invoiceCtrl = require('../controllers/invoice');
const authMiddleware = require('../middlewares/auth');

/**
 * @module routes/invoice
 * @description Ce module gère les routes relatives aux factures, y compris la lecture.
 */
router.get('/', authMiddleware, invoiceCtrl.readAll);
router.get('/:id', authMiddleware, invoiceCtrl.read);

// Lire toutes les factures (ADMIN)
/**
 * @module routes/admin/invoice
 * @description Ce module gère les routes relatives aux factures pour les admins, comprenant la création, la mise à jour et la suppression des factures.
 */
router.get('/admin/', authMiddleware, invoiceCtrl.adminReadAll);
router.post('/admin/', authMiddleware, invoiceCtrl.create);
router.put('/admin/:id', authMiddleware, invoiceCtrl.update);
router.delete('/admin/:id', authMiddleware, invoiceCtrl.delete);

module.exports = router;