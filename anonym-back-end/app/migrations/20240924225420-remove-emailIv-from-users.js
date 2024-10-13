'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  up: async (queryInterface) => {
    await queryInterface.removeColumn('users', 'emailIv');
},

down: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn('users', 'emailIv', {
        type: Sequelize.STRING,
        allowNull: true,
    });
}
};
