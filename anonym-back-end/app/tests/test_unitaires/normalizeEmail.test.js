// normalizeEmail.test.js
const normalizeEmail = require('../../middlewares/normalizeEmail');

describe('normalizeEmail Middleware', () => {
    let req, res, next;

    beforeEach(() => {
        req = {
            body: {}, // Initialiser req.body
        };
        res = {};
        next = jest.fn(); // Moquer la fonction next
    });

    it('should normalize Gmail email addresses in req.body.email', () => {
        req.body.email = 'test.user@gmail.com';

        normalizeEmail(req, res, next); // Appeler le middleware

        expect(req.body.email).toBe('testuser@gmail.com'); // Vérifier que l'email a été normalisé
        expect(next).toHaveBeenCalled(); // Vérifier que next() a été appelé
    });

    it('should not change non-Gmail email addresses in req.body.email', () => {
        req.body.email = 'test.user@yahoo.com';

        normalizeEmail(req, res, next); // Appeler le middleware

        expect(req.body.email).toBe('test.user@yahoo.com'); // Vérifier que l'email n'a pas été modifié
        expect(next).toHaveBeenCalled(); // Vérifier que next() a été appelé
    });

    it('should normalize Gmail email addresses in req.body.identifier', () => {
        req.body.identifier = 'test.user@gmail.com';

        normalizeEmail(req, res, next); // Appeler le middleware

        expect(req.body.identifier).toBe('testuser@gmail.com'); // Vérifier que l'identifier a été normalisé
        expect(next).toHaveBeenCalled(); // Vérifier que next() a été appelé
    });

    it('should not change non-Gmail email addresses in req.body.identifier', () => {
        req.body.identifier = 'test.user@yahoo.com';

        normalizeEmail(req, res, next); // Appeler le middleware

        expect(req.body.identifier).toBe('test.user@yahoo.com'); // Vérifier que l'identifier n'a pas été modifié
        expect(next).toHaveBeenCalled(); // Vérifier que next() a été appelé
    });

    it('should call next() when no email or identifier is provided', () => {
        normalizeEmail(req, res, next); // Appeler le middleware sans email ni identifier

        expect(next).toHaveBeenCalled(); // Vérifier que next() a été appelé
    });
});
