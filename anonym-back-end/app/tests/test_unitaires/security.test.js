const {
    getSafeErrorMessage,
    sanitizeLogPayload,
    sendServerError
} = require('../../utils/security');

const createResponse = () => ({
    status: jest.fn().mockReturnThis(),
    json: jest.fn()
});

describe('security utilities', () => {
    const originalNodeEnv = process.env.NODE_ENV;
    let consoleErrorSpy;

    beforeEach(() => {
        consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
    });

    afterEach(() => {
        process.env.NODE_ENV = originalNodeEnv;
        consoleErrorSpy.mockRestore();
        jest.clearAllMocks();
    });

    it('redacts sensitive values from log payloads', () => {
        const sanitized = sanitizeLogPayload({
            authorization: 'Bearer secret.jwt.token',
            password: 'Password123!',
            nested: {
                refreshToken: 'refresh-secret',
                query: 'token=abc123&ok=true'
            },
            safe: 'visible'
        });

        expect(sanitized).toEqual({
            authorization: '[REDACTED]',
            password: '[REDACTED]',
            nested: {
                refreshToken: '[REDACTED]',
                query: 'token=[REDACTED]&ok=true'
            },
            safe: 'visible'
        });
    });

    it('keeps detailed errors outside production', () => {
        process.env.NODE_ENV = 'test';

        expect(getSafeErrorMessage(new Error('database password leaked'), 'Fallback')).toBe('database password leaked');
    });

    it('returns fallback errors in production responses', () => {
        process.env.NODE_ENV = 'production';
        const res = createResponse();

        sendServerError(res, new Error('database password leaked'), 'Fallback message', {
            token: 'secret-token'
        });

        expect(res.status).toHaveBeenCalledWith(500);
        expect(res.json).toHaveBeenCalledWith({ message: 'Fallback message' });
        expect(consoleErrorSpy).toHaveBeenCalledWith('[SERVER_ERROR]', expect.objectContaining({
            token: '[REDACTED]'
        }));
    });
});
