'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up (queryInterface, Sequelize) {
    await queryInterface.removeColumn('Invoices', 'timestamp');
  },

  async down (queryInterface, Sequelize) {
    await queryInterface.addColumn('Invoices', 'timestamp', {
      type: Sequelize.DATE,
      allowNull: true
    });
  }
};
