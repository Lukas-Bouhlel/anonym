const socketAuth = require('../../middlewares/socketAuth');
const jwt = require('jsonwebtoken');

jest.mock('jsonwebtoken'); // Mock de la bibliothèque jsonwebtoken

describe('Socket Auth Middleware', () => {
    let mockSocket;
    let mockNext;

    beforeEach(() => {
        mockSocket = {
            handshake: {
                query: {},
            },
        };
        mockNext = jest.fn(); // Fonction next mockée
    });

    afterEach(() => {
        jest.clearAllMocks(); // Réinitialiser les mocks
    });

    it('should call next with an error if no token is provided', () => {
        socketAuth(mockSocket, mockNext); // Appeler le middleware sans token
        expect(mockNext).toHaveBeenCalledWith(new Error('Authentication error'));
    });

    it('should call next with an error if token is invalid', () => {
        const invalidToken = 'invalid_token';
        mockSocket.handshake.query.token = invalidToken; // Assigner un token invalide

        // Simuler une erreur de vérification du token
        jwt.verify.mockImplementation(() => {
            throw new Error('Invalid token');
        });

        socketAuth(mockSocket, mockNext); // Appeler le middleware avec un token invalide
        expect(mockNext).toHaveBeenCalledWith(new Error('Authentication error'));
    });

    it('should attach userId to socket and call next if token is valid', () => {
        const validToken = 'valid_token';
        const decodedToken = { userId: '12345' }; // Simuler un jeton décodé valide
        mockSocket.handshake.query.token = validToken; // Assigner un token valide

        // Simuler la vérification du token
        jwt.verify.mockReturnValue(decodedToken);

        socketAuth(mockSocket, mockNext); // Appeler le middleware avec un token valide

        expect(mockSocket.userId).toBe(decodedToken.userId); // Vérifier que l'ID utilisateur a été attaché
        expect(mockNext).toHaveBeenCalled(); // Vérifier que next() a été appelé sans erreur
    });
});