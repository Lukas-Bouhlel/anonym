'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up (queryInterface, Sequelize) {
    await queryInterface.createTable('channels', {
      channel_id: {
        type: Sequelize.INTEGER,
        autoIncrement: true,
        primaryKey: true
      },
      name: {
        type: Sequelize.STRING,
        allowNull: true
      },
      description: {
        type: Sequelize.STRING,
        allowNull: true
      },
      createdAt: {
        allowNull: false,
        type: Sequelize.DATE,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
      },
      updatedAt: {
        allowNull: false,
        type: Sequelize.DATE,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
      }
    });

    await queryInterface.addColumn('private_messages', 'channel_id', {
      type: Sequelize.INTEGER,
      allowNull: false,
      references: {
        model: 'channels',
        key: 'channel_id'
      }
    });
  },

  async down (queryInterface) {
     // Suppression de la colonne channel_id dans private_messages
     await queryInterface.removeColumn('private_messages', 'channel_id');
     // Suppression de la table channels
     await queryInterface.dropTable('channels');
  }
};
