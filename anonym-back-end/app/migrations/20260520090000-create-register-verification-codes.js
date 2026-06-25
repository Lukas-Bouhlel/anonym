'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('register_verification_codes', {
      id: {
        type: Sequelize.INTEGER,
        autoIncrement: true,
        primaryKey: true,
        allowNull: false
      },
      email: {
        type: Sequelize.STRING,
        allowNull: false,
        unique: true
      },
      code_hash: {
        type: Sequelize.STRING(64),
        allowNull: false
      },
      code_expires_at: {
        type: Sequelize.DATE,
        allowNull: false
      },
      last_sent_at: {
        type: Sequelize.DATE,
        allowNull: true
      },
      send_attempts: {
        type: Sequelize.INTEGER,
        allowNull: false,
        defaultValue: 0
      },
      send_window_started_at: {
        type: Sequelize.DATE,
        allowNull: true
      },
      verify_attempts: {
        type: Sequelize.INTEGER,
        allowNull: false,
        defaultValue: 0
      },
      blocked_until: {
        type: Sequelize.DATE,
        allowNull: true
      },
      last_ip: {
        type: Sequelize.STRING(64),
        allowNull: true
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

    await queryInterface.addIndex('register_verification_codes', ['email'], {
      unique: true,
      name: 'register_verification_codes_email_unique'
    });

    await queryInterface.createTable('register_verification_events', {
      id: {
        type: Sequelize.INTEGER,
        autoIncrement: true,
        primaryKey: true,
        allowNull: false
      },
      email: {
        type: Sequelize.STRING,
        allowNull: false
      },
      ip: {
        type: Sequelize.STRING(64),
        allowNull: false
      },
      event_type: {
        type: Sequelize.ENUM('REQUEST_CODE'),
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

    await queryInterface.addIndex('register_verification_events', ['email', 'event_type', 'createdAt'], {
      name: 'register_verification_events_email_event_createdAt_idx'
    });
    await queryInterface.addIndex('register_verification_events', ['ip', 'event_type', 'createdAt'], {
      name: 'register_verification_events_ip_event_createdAt_idx'
    });
  },

  async down(queryInterface) {
    await queryInterface.dropTable('register_verification_events');
    await queryInterface.dropTable('register_verification_codes');
  }
};
