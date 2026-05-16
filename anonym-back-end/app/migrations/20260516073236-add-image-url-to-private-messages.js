'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up (queryInterface, Sequelize) {
    await queryInterface.addColumn('private_messages', 'image_url', {
      type: Sequelize.STRING,
      allowNull: true,
    });
  },

  async down (queryInterface) {
    await queryInterface.removeColumn('private_messages', 'image_url');
  }
};
