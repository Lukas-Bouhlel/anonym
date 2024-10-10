const generateInvoice = require('../../middlewares/generateInvoice');
const { Buffer } = require('buffer');
const PDFDocument = require('pdfkit');

jest.mock('pdfkit'); // Mocker PDFKit

describe('generateInvoice', () => {
    let invoiceData;

    beforeEach(() => {
        invoiceData = {
            id: 'INV-12345',
            username: 'John Doe',
            email: 'john.doe@example.com',
            createdAt: '2023-10-05T12:00:00Z',
            content: 'Service X',
            amount: 100,
            quantity: 2,
        };

        // Reset le mock pour chaque test
        PDFDocument.mockClear();
    });

    it('should generate a PDF without error', async () => {
        const mockPDFDoc = new PDFDocument();
        
        // Mock des méthodes de PDFKit
        mockPDFDoc.on = jest.fn((event, callback) => {
            if (event === 'data') {
                callback(Buffer.from('mocked pdf data'));
            }
            if (event === 'end') {
                callback();
            }
        });

        mockPDFDoc.image = jest.fn(); 
        mockPDFDoc.fontSize = jest.fn();
        mockPDFDoc.text = jest.fn();
        mockPDFDoc.end = jest.fn();

        PDFDocument.mockImplementation(() => mockPDFDoc); // Implémentation du mock

        const pdfData = await generateInvoice(invoiceData);
        expect(pdfData).toBeInstanceOf(Buffer); // Vérifier que le retour est un Buffer
    });

    it('should call PDFKit methods with correct arguments', async () => {
        const mockPDFDoc = new PDFDocument();

        // Mock des méthodes de PDFKit
        mockPDFDoc.on = jest.fn((event, callback) => {
            if (event === 'data') {
                callback(Buffer.from('mocked pdf data'));
            }
            if (event === 'end') {
                callback();
            }
        });

        mockPDFDoc.image = jest.fn(); 
        mockPDFDoc.fontSize = jest.fn();
        mockPDFDoc.text = jest.fn();
        mockPDFDoc.end = jest.fn();

        PDFDocument.mockImplementation(() => mockPDFDoc); 

        await generateInvoice(invoiceData);

        expect(mockPDFDoc.image).toHaveBeenCalledWith(expect.any(String), 40, 35, { width: 80 });
    });
});