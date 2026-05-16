'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface) {
    await queryInterface.sequelize.query(`
      ALTER TABLE friends
      MODIFY COLUMN status ENUM('ACTIVE', 'PENDING', 'BLOQUED')
      NOT NULL DEFAULT 'PENDING'
    `);
  },

  async down(queryInterface) {
    // Repli: toute valeur PENDING est convertie en BLOQUED avant retrait de l'ENUM
    await queryInterface.sequelize.query(`
      UPDATE friends
      SET status = 'BLOQUED'
      WHERE status = 'PENDING'
    `);

    await queryInterface.sequelize.query(`
      ALTER TABLE friends
      MODIFY COLUMN status ENUM('ACTIVE', 'BLOQUED')
      NOT NULL DEFAULT 'ACTIVE'
    `);
  }
};
