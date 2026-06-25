'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn('users', 'presence_status', {
      type: Sequelize.ENUM('online', 'idle', 'dnd', 'invisible'),
      allowNull: false,
      defaultValue: 'online'
    });
  },

  async down(queryInterface) {
    await queryInterface.removeColumn('users', 'presence_status');
    await queryInterface.sequelize.query('DROP TYPE IF EXISTS "enum_users_presence_status";').catch(() => {});
  }
};

