'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up (queryInterface, Sequelize) {
    await queryInterface.addColumn('Users', 'roles', {
      type: Sequelize.ENUM('USER', 'ADMIN', 'SUPER_ADMIN'),
      allowNull: false,
      defaultValue: 'USER'
    });
  },

  async down (queryInterface, Sequelize) {
    await queryInterface.removeColumn('Users', 'roles');
  }
};
