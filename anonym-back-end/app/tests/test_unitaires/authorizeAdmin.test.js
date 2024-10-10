const authorizeAdmin = require('../../middlewares/authorizeAdmin');

describe('authorizeAdmin Middleware', () => {
    let req, res, next;

    beforeEach(() => {
        req = {
            auth: {} // Initialiser req.auth
        };
        res = {
            status: jest.fn().mockReturnThis(), // Moquer la méthode status
            json: jest.fn() // Moquer la méthode json
        };
        next = jest.fn(); // Moquer la fonction next
    });

    it('should call next() if userRole is ADMIN', () => {
        req.auth.userRole = 'ADMIN'; // Simuler un rôle d'utilisateur ADMIN

        authorizeAdmin(req, res, next); // Appeler le middleware

        expect(next).toHaveBeenCalled(); // Vérifier que next() a été appelé
    });

    it('should return 403 if userRole is not ADMIN', () => {
        req.auth.userRole = 'USER'; // Simuler un rôle d'utilisateur non ADMIN

        authorizeAdmin(req, res, next); // Appeler le middleware

        expect(res.status).toHaveBeenCalledWith(403); // Vérifier que le statut 403 a été appelé
        expect(res.json).toHaveBeenCalledWith({ message: 'Accès interdit, vous devez être Admin.' }); // Vérifier que le bon message d'erreur a été renvoyé
        expect(next).not.toHaveBeenCalled(); // Vérifier que next() n'a pas été appelé
    });

    it('should return 403 if userRole is not set', () => {
        // Pas de rôle défini dans req.auth.userRole

        authorizeAdmin(req, res, next); // Appeler le middleware

        expect(res.status).toHaveBeenCalledWith(403); // Vérifier que le statut 403 a été appelé
        expect(res.json).toHaveBeenCalledWith({ message: 'Accès interdit, vous devez être Admin.' }); // Vérifier que le bon message d'erreur a été renvoyé
        expect(next).not.toHaveBeenCalled(); // Vérifier que next() n'a pas été appelé
    });
});
