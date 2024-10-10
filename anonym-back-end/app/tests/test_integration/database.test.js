// database.test.js
const db = require('../../models/index.js');

describe('Database Connection', () => {
    beforeAll(async () => {
        await db.sequelize.authenticate();
    });

    afterAll(async () => {
        await db.sequelize.close();
    });

    it('should connect to the database', async () => {
        await expect(db.sequelize.authenticate()).resolves.not.toThrow();
    });
});
