const os = require('os');
const pinoHttp = require('pino-http');
const client = require('prom-client');

const packageJson = require('../../package.json');

const register = new client.Registry();

client.collectDefaultMetrics({
    register,
    prefix: 'anonym_backend_'
});

const httpRequestDuration = new client.Histogram({
    name: 'anonym_backend_http_request_duration_seconds',
    help: 'HTTP request duration in seconds',
    labelNames: ['method', 'route', 'status_code'],
    buckets: [0.005, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5]
});

const httpRequestsTotal = new client.Counter({
    name: 'anonym_backend_http_requests_total',
    help: 'Total number of HTTP requests',
    labelNames: ['method', 'route', 'status_code']
});

register.registerMetric(httpRequestDuration);
register.registerMetric(httpRequestsTotal);

const normalizeRoute = (path = '/') => {
    return String(path)
        .replace(/\/\d+(?=\/|$)/g, '/:id')
        .replace(/\/[0-9a-fA-F-]{24,36}(?=\/|$)/g, '/:id');
};

const httpLogger = pinoHttp({
    enabled: process.env.NODE_ENV !== 'test',
    redact: {
        paths: [
            'req.headers.authorization',
            'req.headers.cookie',
            'req.headers["x-csrf-token"]',
            'req.body.password',
            'req.body.passwordConfirm',
            'req.body.token',
            'req.body.refreshToken',
            'req.body.resetPasswordToken',
            'res.headers["set-cookie"]'
        ],
        censor: '[REDACTED]'
    },
    customLogLevel: (req, res, error) => {
        if (error || res.statusCode >= 500) return 'error';
        if (res.statusCode >= 400) return 'warn';
        return 'info';
    },
    customProps: (req) => ({
        requestId: req.id,
        route: normalizeRoute(req.path)
    }),
    serializers: {
        req(req) {
            return {
                id: req.id,
                method: req.method,
                url: req.url,
                remoteAddress: req.remoteAddress,
                remotePort: req.remotePort
            };
        },
        res(res) {
            return {
                statusCode: res.statusCode
            };
        }
    }
});

const metricsMiddleware = (req, res, next) => {
    const start = process.hrtime.bigint();

    res.on('finish', () => {
        const durationSeconds = Number(process.hrtime.bigint() - start) / 1e9;
        const labels = {
            method: req.method,
            route: normalizeRoute(req.path),
            status_code: String(res.statusCode)
        };

        httpRequestDuration.observe(labels, durationSeconds);
        httpRequestsTotal.inc(labels);
    });

    next();
};

const getHealthPayload = () => ({
    status: 'ok',
    service: packageJson.name,
    version: packageJson.version,
    environment: process.env.NODE_ENV || 'development',
    uptimeSeconds: Math.round(process.uptime()),
    timestamp: new Date().toISOString(),
    runtime: {
        node: process.version,
        platform: process.platform,
        hostname: os.hostname()
    },
    memory: {
        rss: process.memoryUsage().rss,
        heapUsed: process.memoryUsage().heapUsed,
        heapTotal: process.memoryUsage().heapTotal
    }
});

const healthHandler = (req, res) => {
    return res.status(200).json(getHealthPayload());
};

const metricsHandler = async (req, res) => {
    const configuredToken = process.env.METRICS_TOKEN;
    const providedToken = req.get('x-metrics-token') || req.query?.token;

    if (configuredToken && providedToken !== configuredToken) {
        return res.status(401).json({ message: 'Unauthorized metrics access.' });
    }

    res.set('Content-Type', register.contentType);
    return res.status(200).send(await register.metrics());
};

module.exports = {
    healthHandler,
    httpLogger,
    metricsHandler,
    metricsMiddleware,
    normalizeRoute,
    register
};
