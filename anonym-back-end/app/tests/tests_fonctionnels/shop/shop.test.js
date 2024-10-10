const request = require('supertest');
const app = require('../../../../app');
const { User, Shop, sequelize } = require('../../../models');
const path = require('path');

describe('Shop Routes', () => {
    let adminToken;
    let userToken;
    let adminUser;
    let regularUser;
    let shopItem;

    beforeAll(async () => {
        adminUser = {
            username: 'adminuser',
            email: 'admin@example.com',
            password: 'Password123!',
            roles: 'ADMIN',
        };
        regularUser = {
            username: 'regularuser',
            email: 'regular@example.com',
            password: 'Password123!',
            roles: 'USER',
        };

        // Création des utilisateurs
        await User.create(adminUser);
        await User.create(regularUser);

        // Connexion pour obtenir des tokens
        const adminResponse = await request(app)
            .post('/api/auth/login')
            .send({
                identifier: adminUser.username,
                password: adminUser.password,
            });

        adminToken = adminResponse.body.token; // Stocker le token de l'administrateur

        const userResponse = await request(app)
            .post('/api/auth/login')
            .send({
                identifier: regularUser.username,
                password: regularUser.password,
            });

        userToken = userResponse.body.token; // Stocker le token de l'utilisateur normal
    });

    afterEach(() => {
        jest.clearAllTimers(); // Nettoyer les timers après chaque test
        jest.resetModules();
    });

    afterAll(async () => {
        await User.destroy({ where: {} });
        await Shop.destroy({ where: {} });
        await sequelize.close(); // Fermer la connexion à la base de données après tous les tests
    });

    it('GET /api/shop - should retrieve all shop items', async () => {
        const response = await request(app)
            .get('/api/shop')
            .set('Cookie', `token=${adminToken}`); // Utiliser le token admin

        expect(response.status).toBe(200);
        expect(Array.isArray(response.body)).toBe(true);
    });

    it('GET /api/shop/:id - should retrieve a specific shop item', async () => {
        try {
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
        } catch (error) {
            console.error('Error during test execution:', error);
            throw error; // Rejeter l'erreur pour que Jest la capture correctement
        }
    });

    it('POST /api/shop/admin/ - should create a new shop item', async () => {
        const createResponse = await request(app)
            .post('/api/shop/admin/')
            .set('Cookie', `token=${adminToken}`)
            .field('datas', JSON.stringify({ title: 'New Test Item', amount: 100, type: 'CADRE' }))
            .attach('image', path.join(__dirname, '../../assets/test-image.png')); 
    
        expect(createResponse.status).toBe(201);
        shopItem = createResponse.body;
    });

    it('POST /api/shop/admin/ - should not create an item without required fields', async () => {
        const response = await request(app)
            .post('/api/shop/admin/')
            .set('Cookie', `token=${adminToken}`)
            .field('datas', JSON.stringify({ amount: 150 }))
            .attach('image', path.join(__dirname, '../../assets/test-image.png')); 

        expect(response.status).toBe(400);
        expect(response.body).toHaveProperty('message', "Le titre de l'article est obligatoires");
    });

    it('POST /api/shop/admin/ - should not allow regular users to create items', async () => {
        const response = await request(app)
            .post('/api/shop/admin/')
            .set('Cookie', `token=${userToken}`)
            .field('datas', JSON.stringify({ title: 'User Attempt Item', amount: 100, type: 'CADRE' }))
            .attach('image', path.join(__dirname, '../../assets/test-image.png')); 

        expect(response.status).toBe(403);
        expect(response.body).toHaveProperty('message', "You do not have permission to create an article.");
    });

    it('PUT /api/shop/admin/:id - should update a specific shop item', async () => {
        const response = await request(app)
            .put(`/api/shop/admin/${shopItem.article_id}`)
            .set('Cookie', `token=${adminToken}`)
            .field('datas', JSON.stringify({ title: 'Updated Test Item', amount: 120 }))

        expect(response.status).toBe(201);
        expect(response.body).toHaveProperty('title', 'Updated Test Item');
    });

    it('DELETE /api/shop/admin/:id - should delete a specific shop item', async () => {
        const response = await request(app)
            .delete(`/api/shop/admin/${shopItem.article_id}`)
            .set('Cookie', `token=${adminToken}`);

        expect(response.status).toBe(204);
    });
});
