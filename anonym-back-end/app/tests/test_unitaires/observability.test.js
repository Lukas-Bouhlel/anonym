const request = require('supertest');

const app = require('../../../app');

describe('observability endpoints', () => {
    afterEach(() => {
        delete process.env.METRICS_TOKEN;
    });

    it('returns a public health payload', async () => {
        const response = await request(app).get('/health');

        expect(response.status).toBe(200);
        expect(response.body).toMatchObject({
            status: 'ok',
            service: 'anonym-back-end'
        });
        expect(response.body).toHaveProperty('uptimeSeconds');
        expect(response.body).toHaveProperty('memory.rss');
    });

    it('exposes /status and /api/health aliases', async () => {
        const statusResponse = await request(app).get('/status');
        const apiHealthResponse = await request(app).get('/api/health');

        expect(statusResponse.status).toBe(200);
        expect(apiHealthResponse.status).toBe(200);
        expect(statusResponse.body.status).toBe('ok');
        expect(apiHealthResponse.body.status).toBe('ok');
    });

    it('exposes prometheus metrics', async () => {
        await request(app).get('/health');

        const response = await request(app).get('/metrics');

        expect(response.status).toBe(200);
        expect(response.text).toContain('anonym_backend_http_requests_total');
        expect(response.text).toContain('anonym_backend_http_request_duration_seconds');
    });

    it('can protect metrics with METRICS_TOKEN', async () => {
        process.env.METRICS_TOKEN = 'metrics-secret';

        const unauthorizedResponse = await request(app).get('/metrics');
        const authorizedResponse = await request(app)
            .get('/metrics')
            .set('x-metrics-token', 'metrics-secret');

        expect(unauthorizedResponse.status).toBe(401);
        expect(authorizedResponse.status).toBe(200);
    });
});
