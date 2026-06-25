'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.changeColumn('users', 'presence_status', {
      type: Sequelize.ENUM('online', 'idle', 'dnd', 'invisible'),
      allowNull: false,
      defaultValue: 'invisible'
    });

    // Normalize existing rows to offline-by-default.
    // Active users will be switched to online when their socket connects.
    await queryInterface.sequelize.query(
      "UPDATE users SET presence_status = 'invisible' WHERE presence_status = 'online';"
    );
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.changeColumn('users', 'presence_status', {
      type: Sequelize.ENUM('online', 'idle', 'dnd', 'invisible'),
      allowNull: false,
      defaultValue: 'online'
    });
  }
};

