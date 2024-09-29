'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up (queryInterface, Sequelize) {
    await queryInterface.addColumn('private_messages', 'status', {
      type: Sequelize.STRING,
      allowNull: false,
      defaultValue: 'unread',  // Valeur par défaut pour les messages non lus
    });
  },

  async down (queryInterface, Sequelize) {
    await queryInterface.removeColumn('private_messages', 'status');
  }
};
