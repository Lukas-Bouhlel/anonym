const generateAvatar = require('../../middlewares/generateAvatar');

describe('generateAvatar Middleware', () => {
    let req, res, next;

    beforeEach(() => {
        req = { body: {} }; // Initialiser req.body
        res = {
            status: jest.fn().mockReturnThis(), // Moquer la méthode status
            json: jest.fn(), // Moquer la méthode json
        };
        next = jest.fn(); // Moquer la fonction next
    });

    it('should generate pastel colors and attach to req.avatarData when no file or avatar provided', () => {
        generateAvatar(req, res, next); // Appeler le middleware
        
        expect(req.avatarData).toBeDefined(); // Vérifier que avatarData est défini
        expect(req.avatarData.circleColor).toMatch(/^#[0-9a-f]{6}$/i); // Vérifier que la couleur est au format hexadécimal
        expect(req.avatarData.pathColor).toBeDefined(); // Vérifier que pathColor est défini
        expect(req.avatarData.uniqueAvatarName).toMatch(/avatar_\d+\.svg$/); // Vérifier que le nom de l'avatar est au bon format
        expect(next).toHaveBeenCalled(); // Vérifier que next() a été appelé
    });

    it('should not generate avatar data when file or avatar is provided', () => {
        req.file = {}; // Simuler la présence d'un fichier
        generateAvatar(req, res, next); // Appeler le middleware

        expect(req.avatarData).toBeUndefined(); // Vérifier que avatarData n'est pas défini
        expect(next).toHaveBeenCalled(); // Vérifier que next() a été appelé
    });

    it('should handle errors correctly', () => {
        // Simuler une erreur en forçant une exception
        req.file = undefined; // Assurer que req.file est undefined pour éviter la condition
        jest.spyOn(Math, 'random').mockImplementationOnce(() => { throw new Error('Test error'); }); // Simuler une erreur dans la génération de couleur

        generateAvatar(req, res, next); // Appeler le middleware

        expect(res.status).toHaveBeenCalledWith(500); // Vérifier que le statut 500 a été appelé
        expect(res.json).toHaveBeenCalledWith({ message: 'Test error' }); // Vérifier le message d'erreur
    });
});
