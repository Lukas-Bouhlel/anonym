'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up (queryInterface, Sequelize) {
    await queryInterface.changeColumn('Shops', 'content', {
      type: Sequelize.STRING(255),
      allowNull: false
    });
  },

  async down (queryInterface, Sequelize) {
    await queryInterface.changeColumn('Shops', 'content', {
      type: Sequelize.BLOB,
      allowNull: false
    });
  }
};
