const SENSITIVE_KEYS = [
    'authorization',
    'cookie',
    'password',
    'token',
    'refreshToken',
    'session',
    'secret',
    'stripe',
    'mail_pass'
];

const isProduction = () => process.env.NODE_ENV === 'production';

const redactValue = (key, value) => {
    const normalizedKey = String(key || '').toLowerCase();
    if (SENSITIVE_KEYS.some((sensitiveKey) => normalizedKey.includes(sensitiveKey.toLowerCase()))) {
        return '[REDACTED]';
    }

    if (typeof value === 'string') {
        return value
            .replace(/Bearer\s+[A-Za-z0-9._~+/=-]+/gi, 'Bearer [REDACTED]')
            .replace(/(token|password|secret|authorization)=([^&\s]+)/gi, '$1=[REDACTED]');
    }

    return value;
};

const sanitizeLogPayload = (payload) => {
    if (!payload || typeof payload !== 'object') return payload;

    return Object.entries(payload).reduce((accumulator, [key, value]) => {
        if (value && typeof value === 'object' && !Array.isArray(value)) {
            accumulator[key] = sanitizeLogPayload(value);
        } else {
            accumulator[key] = redactValue(key, value);
        }
        return accumulator;
    }, {});
};

const secureLog = (level, message, payload = {}) => {
    const logger = console[level] || console.error;
    logger(message, sanitizeLogPayload(payload));
};

const getSafeErrorMessage = (error, fallbackMessage = 'Une erreur interne est survenue.') => {
    if (isProduction()) {
        return fallbackMessage;
    }

    return error?.message || fallbackMessage;
};

const sendServerError = (res, error, fallbackMessage, logContext = {}) => {
    secureLog('error', '[SERVER_ERROR]', {
        ...logContext,
        errorName: error?.name,
        errorMessage: error?.message
    });

    return res.status(500).json({
        message: getSafeErrorMessage(error, fallbackMessage)
    });
};

module.exports = {
    getSafeErrorMessage,
    sanitizeLogPayload,
    secureLog,
    sendServerError
};
