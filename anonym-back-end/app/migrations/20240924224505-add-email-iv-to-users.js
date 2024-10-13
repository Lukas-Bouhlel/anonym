'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up (queryInterface, Sequelize) {
    await queryInterface.addColumn('users', 'emailIv', {
      type: Sequelize.STRING,
      allowNull: false, // ou true, selon tes besoins
    });
  },

  async down (queryInterface) {
    await queryInterface.removeColumn('users', 'emailIv');
  }
};
