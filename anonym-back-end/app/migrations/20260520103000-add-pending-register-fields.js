'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn('register_verification_codes', 'pending_username', {
      type: Sequelize.STRING,
      allowNull: true
    });

    await queryInterface.addColumn('register_verification_codes', 'pending_password_hash', {
      type: Sequelize.STRING,
      allowNull: true
    });
  },

  async down(queryInterface) {
    await queryInterface.removeColumn('register_verification_codes', 'pending_password_hash');
    await queryInterface.removeColumn('register_verification_codes', 'pending_username');
  }
};
