'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up (queryInterface, Sequelize) {
    await queryInterface.createTable('private_messages', {
      message_id: {
          type: Sequelize.INTEGER,
          autoIncrement: true,
          primaryKey: true,
          allowNull: false
      },
      sender_id: {
          type: Sequelize.INTEGER,
          allowNull: false,
          references: {
              model: 'users', // nom de la table des utilisateurs
              key: 'id'
          },
          onDelete: 'CASCADE',
          onUpdate: 'CASCADE'
      },
      receiver_id: {
          type: Sequelize.INTEGER,
          allowNull: false,
          references: {
              model: 'users', // nom de la table des utilisateurs
              key: 'id'
          },
          onDelete: 'CASCADE',
          onUpdate: 'CASCADE'
      },
      content: {
          type: Sequelize.TEXT,
          allowNull: false
      },
      createdAt: {
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
      },
      updatedAt: {
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
      }
  });
  },

  async down (queryInterface) {
    await queryInterface.dropTable('private_messages');
  }
};
