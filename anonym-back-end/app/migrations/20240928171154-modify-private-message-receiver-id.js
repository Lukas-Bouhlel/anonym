'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up (queryInterface) {
    await queryInterface.removeColumn('private_messages', 'receiver_id');
  },

  async down (queryInterface, Sequelize) {
    await queryInterface.addColumn('private_messages', 'receiver_id', {
      type: Sequelize.INTEGER,
      allowNull: true, // Le rendre optionnel si vous voulez pouvoir annuler la suppression
    });
  }
};
