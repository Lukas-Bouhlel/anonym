const request = require('supertest');
const app = require('../../../../app');
const { User, Shop, Invoice, sequelize } = require('../../../models');

describe('Payment Routes', () => {
    let user;
    let token; 

    beforeAll(async () => {
        // Créer un utilisateur de test
        const userCreate = {
            username: 'testuser',
            email: 'testuser@example.com',
            password: 'Password123!',
        };

        user = await User.create(userCreate); // Créer l'utilisateur dans la base de données

        // Créer un article de test
        await Shop.create({
            article_id: '1',
            title: 'Test Item',
            amount: 10,
            content: 'http://example.com/image.png',
            type: 'CADRE'
        });
    });

    afterEach(() => {
        jest.clearAllTimers(); // Nettoyer tous les timers
        jest.resetModules();
    });

    afterAll(async () => {
        await User.destroy({ where: {} });
        await Shop.destroy({ where: {} });
        await Invoice.destroy({ where: {} });
        await sequelize.close(); // Fermer la connexion à la base de données
    });

    // Connexion pour obtenir le token JWT avant chaque test
    beforeEach(async () => {
        const response = await request(app)
            .post('/api/auth/login')
            .send({
                identifier: user.dataValues.username,
                password: 'Password123!', // Corriger l'accès au mot de passe
            });

        token = response.body.token; // Récupérer le token
    });

    test('User should create a payment session successfully', async () => {
        const response = await request(app)
            .post('/api/payment')
            .set('Cookie', `token=${token}`)
            .send({ article_id: '1' }); // ID de l'article

        expect(response.status).toBe(200);
        expect(response.body).toHaveProperty('url'); // Vérifier que l'URL de session de paiement est présente
        expect(response.body.url).toMatch(/https:\/\/checkout\.stripe\.com\/c\/pay/); // Vérifier que l'URL commence par le bon domaine Stripe
    });

    test('User should receive 400 error if article_id is missing', async () => {
        const response = await request(app)
            .post('/api/payment')
            .set('Cookie', `token=${token}`)
            .send({}); // Ne pas envoyer article_id

        expect(response.status).toBe(400);
        expect(response.body).toHaveProperty('message', "Article ID is required.");
    });

    test('User should receive 404 error if item does not exist', async () => {
        const response = await request(app)
            .post('/api/payment')
            .set('Cookie', `token=${token}`)
            .send({ article_id: 'non-existent-id' }); // Envoyer un ID d'article inexistant

        expect(response.status).toBe(404);
        expect(response.body).toHaveProperty('message', "Item not found.");
    });

    test('User should receive 400 error if item was already purchased', async () => {
        // Simuler l'achat
        await Invoice.create({
            user_id: user.dataValues.id,
            article_id: '1',
            amount: 10,
            type: "CADRE",
            content: 'test',
            quantity: 1
        });

        const response = await request(app)
            .post('/api/payment')
            .set('Cookie', `token=${token}`)
            .send({ article_id: '1' });

        expect(response.status).toBe(400);
        expect(response.body).toHaveProperty('message', "You have already purchased this item.");
    });


    test('User should receive 400 error if session_id is missing on confirm', async () => {
        const response = await request(app)
            .get('/api/payment/confirm') // Ne pas envoyer session_id
            .set('Cookie', `token=${token}`);

        expect(response.status).toBe(400);
        expect(response.body).toHaveProperty('message', 'Session ID is required.');
    });
    
});
