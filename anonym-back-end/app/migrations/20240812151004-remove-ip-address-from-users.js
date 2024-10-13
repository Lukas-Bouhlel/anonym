'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up (queryInterface) {
    await queryInterface.removeColumn('users', 'ip_address');
  },

  async down (queryInterface, Sequelize) {
    await queryInterface.addColumn('users', 'ip_address', {
      type: Sequelize.STRING,
      allowNull: false,
    });
  }
};
