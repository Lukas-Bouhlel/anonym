const authorizeAdmin = require('../../middlewares/authorizeAdmin');

const createResponse = () => ({
    status: jest.fn().mockReturnThis(),
    json: jest.fn()
});

describe('authorizeAdmin middleware', () => {
    it('rejects requests without an admin role', () => {
        const req = { auth: { userRole: 'USER' } };
        const res = createResponse();
        const next = jest.fn();

        authorizeAdmin(req, res, next);

        expect(res.status).toHaveBeenCalledWith(403);
        expect(res.json).toHaveBeenCalledWith({
            message: 'Accès interdit, vous devez être Admin.'
        });
        expect(next).not.toHaveBeenCalled();
    });

    it('allows ADMIN requests', () => {
        const req = { auth: { userRole: 'ADMIN' } };
        const res = createResponse();
        const next = jest.fn();

        authorizeAdmin(req, res, next);

        expect(next).toHaveBeenCalledTimes(1);
        expect(res.status).not.toHaveBeenCalled();
    });

    it('allows SUPER_ADMIN requests', () => {
        const req = { auth: { userRole: 'SUPER_ADMIN' } };
        const res = createResponse();
        const next = jest.fn();

        authorizeAdmin(req, res, next);

        expect(next).toHaveBeenCalledTimes(1);
        expect(res.status).not.toHaveBeenCalled();
    });
});
