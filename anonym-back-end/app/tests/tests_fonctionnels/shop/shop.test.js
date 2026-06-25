const request = require('supertest');
const app = require('../../../../app');
const { User, Shop, sequelize } = require('../../../models');
const path = require('path');
const { cleanupAuthData, createUser, login, strongPassword } = require('../../testUtils');

describe('Shop Routes', () => {
    let adminToken;
    let shopItem;
    const adminUser = {
        username: 'adminuser',
        email: 'admin@example.com',
        password: strongPassword,
        roles: 'ADMIN',
    };
    const regularUser = {
        username: 'regularuser',
        email: 'regular@example.com',
        password: strongPassword,
        roles: 'USER',
    };

    beforeAll(async () => {
        await cleanupAuthData();
        await Shop.destroy({ where: {} });
        await User.destroy({ where: {} });

        await createUser(adminUser);
        await createUser(regularUser);

        const { response: adminResponse } = await login(app, adminUser.username, adminUser.password);
        expect(adminResponse.status).toBe(200);

        adminToken = adminResponse.body.token;
    });

    afterEach(() => {
        jest.clearAllTimers();
        jest.resetModules();
    });

    afterAll(async () => {
        await Shop.destroy({ where: {} });
        await cleanupAuthData();
        await User.destroy({ where: {} });
        await sequelize.close();
    });

    it('GET /api/shop - should retrieve all shop items', async () => {
        const response = await request(app)
            .get('/api/shop')
            .set('Cookie', `token=${adminToken}`);

        expect(response.status).toBe(200);
        expect(Array.isArray(response.body)).toBe(true);
    });

    it('GET /api/shop/:id - should retrieve a specific shop item', async () => {
        const createResponse = await request(app)
            .post('/api/shop/admin/')
            .set('Cookie', `token=${adminToken}`)
            .field('datas', JSON.stringify({ title: 'Test Item', amount: 100, type: 'CADRE' }))
            .attach('image', path.join(__dirname, '../../assets/test-image.png'));

        expect(createResponse.status).toBe(201);
        shopItem = createResponse.body;

        const response = await request(app)
            .get(`/api/shop/${shopItem.article_id}`)
            .set('Cookie', `token=${adminToken}`);

        expect(response.status).toBe(200);
        expect(response.body).toHaveProperty('article_id', shopItem.article_id);
    });

    it('POST /api/shop/admin/ - should create a new shop item', async () => {
        const createResponse = await request(app)
            .post('/api/shop/admin/')
            .set('Cookie', `token=${adminToken}`)
            .field('datas', JSON.stringify({ title: 'New Test Item', amount: 100, type: 'CADRE' }))
            .attach('image', path.join(__dirname, '../../assets/test-image.png'));

        expect(createResponse.status).toBe(201);
        expect(createResponse.body).toHaveProperty('article_id');
    });

    it('POST /api/shop/admin/ - should reject non-image uploads', async () => {
        const response = await request(app)
            .post('/api/shop/admin/')
            .set('Cookie', `token=${adminToken}`)
            .field('datas', JSON.stringify({ title: 'Invalid Upload Item', amount: 100, type: 'CADRE' }))
            .attach('image', Buffer.from('<svg><script>alert(1)</script></svg>'), {
                filename: 'payload.svg',
                contentType: 'image/svg+xml'
            });

        expect(response.status).toBe(400);
        expect(response.body).toHaveProperty('message', 'Fichier image invalide.');
    });
});
