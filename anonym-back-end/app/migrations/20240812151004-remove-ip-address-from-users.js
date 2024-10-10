'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up (queryInterface) {
    await queryInterface.removeColumn('Users', 'ip_address');
  },

  async down (queryInterface, Sequelize) {
    await queryInterface.addColumn('Users', 'ip_address', {
      type: Sequelize.STRING,
      allowNull: false,
    });
  }
};
