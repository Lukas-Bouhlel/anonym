'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up (queryInterface) {
    await queryInterface.removeColumn('Inventories', 'friend_id');

  },

  async down (queryInterface, Sequelize) {
    await queryInterface.addColumn('Inventories', 'friend_id', {
      type: Sequelize.INTEGER,
      allowNull: true,
      references: {
        model: 'friends', // nom de la table amis
        key: 'id' // clé primaire de la table amis
      }
    });
  }
};
