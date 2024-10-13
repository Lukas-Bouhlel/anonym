'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up (queryInterface, Sequelize) {
    await queryInterface.addColumn('inventories', 'friend_id', {
      type: Sequelize.INTEGER,
      allowNull: true, // ou false si vous voulez que cette colonne soit obligatoire
      references: {
          model: 'friends', // Assurez-vous que cette table existe
          key: 'id'
      },
      onUpdate: 'CASCADE',
      onDelete: 'SET NULL' // ou 'CASCADE', selon votre besoin
  });
  },

  async down (queryInterface) {
    await queryInterface.removeColumn('inventories', 'friend_id');
  }
};
