const { User } = require('../../models');
const authController = require('../../controllers/auth');

jest.mock('../../models', () => ({
    User: {
        findOne: jest.fn()
    },
    RefreshToken: {},
    RegisterVerificationCode: {},
    RegisterVerificationEvent: {}
}));

const createResponse = () => ({
    status: jest.fn().mockReturnThis(),
    json: jest.fn()
});

const requestReset = async (platform) => {
    const user = {
        email: 'user@example.com',
        save: jest.fn().mockResolvedValue(undefined)
    };
    const mailer = {
        sendEmail: jest.fn().mockResolvedValue(undefined)
    };
    User.findOne.mockResolvedValue(user);

    const req = {
        body: {
            email: user.email,
            ...(platform ? { platform } : {})
        },
        mailer
    };
    const res = createResponse();

    await authController.requestPasswordReset(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(mailer.sendEmail).toHaveBeenCalledTimes(1);
    return mailer.sendEmail.mock.calls[0][3];
};

describe('Auth Controller - password reset platform', () => {
    const originalEnv = { ...process.env };

    beforeEach(() => {
        jest.clearAllMocks();
        process.env.RESET_PASSWORD_WEB_URL = 'https://web.example.com';
        process.env.RESET_PASSWORD_MOBILE_URL = 'anonym:///auth/reset';
        delete process.env.MOBILE_DEEP_LINK_BASE_URL;
    });

    afterAll(() => {
        process.env = originalEnv;
    });

    it('puts a direct application deep link in emails requested by the mobile app', async () => {
        const html = await requestReset('mobile');

        expect(html).toMatch(/href="anonym:\/\/\/auth\/reset\?token=[a-f0-9]+"/);
        expect(html).not.toContain('/open-reset-password');
        expect(html).not.toContain('href="https://web.example.com/reset/');
    });

    it('builds the reset route from the shared mobile deep-link base', async () => {
        delete process.env.RESET_PASSWORD_MOBILE_URL;
        process.env.MOBILE_DEEP_LINK_BASE_URL = 'anonym://';

        const html = await requestReset('mobile');

        expect(html).toMatch(/href="anonym:\/\/\/auth\/reset\?token=[a-f0-9]+"/);
    });

    it('puts a web link in emails requested by the website', async () => {
        const html = await requestReset('web');

        expect(html).toMatch(/href="https:\/\/web\.example\.com\/reset\/\?token=[a-f0-9]+"/);
        expect(html).not.toContain('/open-reset-password');
        expect(html).not.toContain('href="anonym:');
    });

    it('keeps the web destination for clients that do not send a platform', async () => {
        const html = await requestReset();

        expect(html).toMatch(/href="https:\/\/web\.example\.com\/reset\/\?token=[a-f0-9]+"/);
    });
});
