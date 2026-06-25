'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn('channels', 'channel_type', {
      type: Sequelize.ENUM('PRIVATE_DM', 'GROUP'),
      allowNull: false,
      defaultValue: 'GROUP'
    });

    await queryInterface.addColumn('channels', 'visibility', {
      type: Sequelize.ENUM('PUBLIC', 'PRIVATE'),
      allowNull: false,
      defaultValue: 'PRIVATE'
    });

    await queryInterface.createTable('channel_invites', {
      invite_id: {
        type: Sequelize.INTEGER,
        autoIncrement: true,
        primaryKey: true,
        allowNull: false
      },
      channel_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'channels',
          key: 'channel_id'
        },
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE'
      },
      code: {
        type: Sequelize.STRING(64),
        allowNull: false,
        unique: true
      },
      created_by: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'users',
          key: 'id'
        },
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE'
      },
      expires_at: {
        type: Sequelize.DATE,
        allowNull: true
      },
      max_uses: {
        type: Sequelize.INTEGER,
        allowNull: true
      },
      uses_count: {
        type: Sequelize.INTEGER,
        allowNull: false,
        defaultValue: 0
      },
      is_active: {
        type: Sequelize.BOOLEAN,
        allowNull: false,
        defaultValue: true
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

  async down(queryInterface) {
    await queryInterface.dropTable('channel_invites');
    await queryInterface.removeColumn('channels', 'visibility');
    await queryInterface.removeColumn('channels', 'channel_type');
  }
};
