const bcrypt = require('bcrypt');
const { User, RefreshToken } = require('../../models');
const authController = require('../../controllers/auth');

jest.mock('bcrypt');
jest.mock('../../models', () => ({
    User: {
        findOne: jest.fn()
    },
    RefreshToken: {
        create: jest.fn()
    },
    RegisterVerificationCode: {},
    RegisterVerificationEvent: {}
}));

const createResponse = () => ({
    cookie: jest.fn(),
    status: jest.fn().mockReturnThis(),
    json: jest.fn()
});

const createRequest = (body) => ({
    body,
    ip: '127.0.0.1',
    get: jest.fn().mockReturnValue('jest-agent')
});

describe('Auth Controller - admin login', () => {
    beforeEach(() => {
        process.env.JWT_SECRET = 'test-secret';
        jest.clearAllMocks();
        RefreshToken.create.mockResolvedValue({});
    });

    it('rejects a non-admin user with valid credentials', async () => {
        User.findOne.mockResolvedValue({
            id: 1,
            username: 'regularuser',
            password: 'hashed-password',
            roles: 'USER'
        });
        bcrypt.compare.mockResolvedValue(true);

        const req = createRequest({
            identifier: 'regularuser',
            password: 'Password123!'
        });
        const res = createResponse();

        await authController.loginAdmin(req, res);

        expect(res.status).toHaveBeenCalledWith(403);
        expect(res.json).toHaveBeenCalledWith({
            message: 'Acces interdit, vous devez etre administrateur.'
        });
        expect(RefreshToken.create).not.toHaveBeenCalled();
        expect(res.cookie).not.toHaveBeenCalled();
    });

    it('logs in an admin user', async () => {
        User.findOne.mockResolvedValue({
            id: 2,
            username: 'adminuser',
            password: 'hashed-password',
            roles: 'ADMIN'
        });
        bcrypt.compare.mockResolvedValue(true);

        const req = createRequest({
            identifier: 'adminuser',
            password: 'Password123!'
        });
        const res = createResponse();

        await authController.loginAdmin(req, res);

        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
            token: expect.any(String),
            user: expect.objectContaining({ roles: 'ADMIN' })
        }));
        expect(RefreshToken.create).toHaveBeenCalled();
        expect(res.cookie).toHaveBeenCalledWith('token', expect.any(String), expect.any(Object));
        expect(res.cookie).toHaveBeenCalledWith('refreshToken', expect.any(String), expect.any(Object));
    });
});
