'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up (queryInterface, Sequelize) {
    await queryInterface.createTable('user_channels', {
      user_id: {
          type: Sequelize.INTEGER,
          references: {
              model: 'Users', // Nom de la table des utilisateurs
              key: 'id'
          },
          onDelete: 'CASCADE', // Supprimer les relations si l'utilisateur est supprimé
          allowNull: false
      },
      channel_id: {
          type: Sequelize.INTEGER,
          references: {
              model: 'channels', // Nom de la table des canaux
              key: 'channel_id'
          },
          onDelete: 'CASCADE', // Supprimer les relations si le canal est supprimé
          allowNull: false
      },
      createdAt: {
          allowNull: false,
          type: Sequelize.DATE,
          defaultValue: Sequelize.fn('NOW')
      },
      updatedAt: {
          allowNull: false,
          type: Sequelize.DATE,
          defaultValue: Sequelize.fn('NOW')
      }
  });
  },

  async down (queryInterface, Sequelize) {
    await queryInterface.dropTable('user_channels'); // Supprimer la table en cas de rollback
  }
};
