const express = require('express');
const router = express.Router();
const invoiceCtrl = require('../controllers/invoice');
const authMiddleware = require('../middlewares/auth');

// Lire toutes les factures du user connecté
router.get('/', authMiddleware, invoiceCtrl.readAll);

// Lire une facture par ID
router.get('/:id', authMiddleware, invoiceCtrl.read);

// Lire toutes les factures (ADMIN)
router.get('/admin/', authMiddleware, invoiceCtrl.adminReadAll);

// Créer une nouvelle facture (ADMIN)
router.post('/admin/', authMiddleware, invoiceCtrl.create);

// Mettre à jour une facture (ADMIN)
router.put('/admin/:id', authMiddleware, invoiceCtrl.update);

// Supprimer une facture (ADMIN)
router.delete('/admin/:id', authMiddleware, invoiceCtrl.delete);

module.exports = router;