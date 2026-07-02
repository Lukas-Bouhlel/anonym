// authMiddleware.test.js
const jwt = require('jsonwebtoken');
const authMiddleware = require('../../middlewares/auth');

jest.mock('jsonwebtoken'); // Moquer la bibliothèque jsonwebtoken

describe('Auth Middleware', () => {
    let req, res, next;

    beforeEach(() => {
        req = {
            cookies: {}, // Initialiser les cookies vides
        };
        res = {
            clearCookie: jest.fn(),
            status: jest.fn().mockReturnThis(), // Moquer la méthode status
            json: jest.fn(), // Moquer la méthode json
        };
        next = jest.fn(); // Moquer la fonction next
    });

    it('should attach userId and userRole to request when token is valid', () => {
        const token = 'valid-token';
        const decodedToken = { userId: '123', userRole: 'admin' };
        
        req.cookies.token = token; // Simuler le cookie contenant le token
        jwt.verify.mockReturnValue(decodedToken); // Moquer le comportement de jwt.verify

        authMiddleware(req, res, next); // Appeler le middleware

        expect(req.auth).toEqual({ userId: '123', userRole: 'admin' }); // Vérifier que les valeurs sont attachées
        expect(next).toHaveBeenCalled(); // Vérifier que next() a été appelé
    });

    it('should return 401 when token is invalid', () => {
        const token = 'invalid-token';
        req.cookies.token = token;

        jwt.verify.mockImplementation(() => {
            throw new Error('Invalid token'); // Simuler une erreur lors de la vérification du token
        });

        authMiddleware(req, res, next); // Appeler le middleware

        expect(res.status).toHaveBeenCalledWith(401); // Vérifier que le statut 401 a été appelé
        expect(res.json).toHaveBeenCalledWith({ error: 'Unauthorized request!' }); // Vérifier que le message d'erreur a été envoyé
        expect(res.clearCookie).toHaveBeenCalledWith('token', expect.any(Object));
        expect(res.clearCookie).not.toHaveBeenCalledWith('refreshToken', expect.any(Object));
        expect(next).not.toHaveBeenCalled(); // Vérifier que next() n'a pas été appelé
    });

    it('should return 401 when token is not present', () => {
        authMiddleware(req, res, next); // Appeler le middleware sans token

        expect(res.status).toHaveBeenCalledWith(401); // Vérifier que le statut 401 a été appelé
        expect(res.json).toHaveBeenCalledWith({ error: 'Unauthorized request!' }); // Vérifier que le message d'erreur a été envoyé
        expect(next).not.toHaveBeenCalled(); // Vérifier que next() n'a pas été appelé
    });
});
