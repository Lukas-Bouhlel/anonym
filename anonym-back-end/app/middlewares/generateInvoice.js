const { JSDOM } = require('jsdom');
const { Buffer } = require('buffer');
const DOMPurify = require('dompurify');
const PDFDocument = require('pdfkit');
const path = require('path');

// Créer un DOM virtuel pour DOMPurify
const window = new JSDOM('').window;
const purify = DOMPurify(window);

const drawTable = (doc, startX, startY, headers, rows) => {
    const rowHeight = 25;
    const colWidth = (doc.page.width - 100) / headers.length; 
    const padding = 5;

    // Dessiner les en-têtes
    headers.forEach((header, i) => {
        doc.text(header, startX + (i * colWidth) + padding, startY + padding);
        doc.rect(startX + (i * colWidth), startY, colWidth, rowHeight).stroke();
    });

    // Dessiner les lignes de données
    rows.forEach((row, i) => {
        const rowY = startY + (i + 1) * rowHeight;
        row.forEach((cell, j) => {
            doc.text(cell, startX + (j * colWidth) + padding, rowY + padding);
            doc.rect(startX + (j * colWidth), rowY, colWidth, rowHeight).stroke();
        });
        doc.moveTo(startX, rowY + rowHeight).lineTo(startX + (colWidth * headers.length), rowY + rowHeight).stroke();
    });

    doc.moveTo(startX, startY + rowHeight).lineTo(startX + (colWidth * headers.length), startY + rowHeight).stroke();
};

const generateInvoice = async (invoiceData) => {
    return new Promise((resolve) => {
        const doc = new PDFDocument();
        let buffers = [];

        doc.on('data', buffers.push.bind(buffers));
        doc.on('end', () => {
            const pdfData = Buffer.concat(buffers);
            resolve(pdfData);
        });

        // Ajouter le contenu du PDF
        const imagePath = path.join(__dirname, '../../uploads/profiles/default/anonym-logo.png');

        doc.image(imagePath, 40, 35, { width: 80 })
            .fontSize(20).text('Facture', { align: 'center' }).moveDown(3);

        // Informations de l'entreprise
        doc.fontSize(14).text('Anonym');
        doc.fontSize(12).text('dpo@anonym-tech.fr');
        doc.text('18 rue professeur Joseph Nicolas');
        doc.text('RCS 1092838');
        doc.text('Numéro de TVA 3920323');
        doc.moveDown(2);
        doc.moveTo(50, doc.y).lineTo(550, doc.y).stroke().moveDown(2);

        // Informations de l'utilisateur
        doc.fontSize(14).text('Facturé à');
        doc.fontSize(12).text(`Numéro de facture: ${purify.sanitize(invoiceData.id)}`);
        doc.text(`Nom: ${purify.sanitize(invoiceData.username)}`);
        doc.text(`Email: ${purify.sanitize(invoiceData.email)}`);
        doc.text(`Date: ${new Date(invoiceData.createdAt).toLocaleDateString()}`);
        doc.moveDown(2);
        doc.moveTo(50, doc.y).lineTo(550, doc.y).stroke().moveDown(2);

        // Détails de la facture
        doc.fontSize(14).text('Détails de la facture').moveDown(2);
        const headers = ['Article', 'Montant', 'Quantité'];
        const rows = [[purify.sanitize(invoiceData.content), `${purify.sanitize(invoiceData.amount)}€`, purify.sanitize(invoiceData.quantity)]];
        drawTable(doc, 50, doc.y, headers, rows);
        doc.moveDown(2);

        // Total
        doc.text(`Total: ${purify.sanitize(invoiceData.amount * invoiceData.quantity)}€`).moveDown(2);
        doc.end(); // Fin du document
    });
};

module.exports = generateInvoice;