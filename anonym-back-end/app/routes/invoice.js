const express = require('express');
const router = express.Router();
const invoiceCtrl = require('../controllers/invoice');
const authMiddleware = require('../middlewares/auth');

// Lire toutes les factures du user connecté
router.get('/', authMiddleware, invoiceCtrl.readAll);

// Lire toutes les factures (ADMIN)
router.get('/admin/', authMiddleware, invoiceCtrl.adminReadAll);

// Lire une facture par ID
router.get('/:id', authMiddleware, invoiceCtrl.read);

// Créer une nouvelle facture (ADMIN)
router.post('/', authMiddleware, invoiceCtrl.create);

// Mettre à jour une facture (ADMIN)
router.put('/:id', authMiddleware, invoiceCtrl.update);

// Supprimer une facture (ADMIN)
router.delete('/:id', authMiddleware, invoiceCtrl.delete);

module.exports = router;