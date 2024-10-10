'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  up: async (queryInterface) => {
    await queryInterface.removeColumn('Users', 'emailIv');
},

down: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn('Users', 'emailIv', {
        type: Sequelize.STRING,
        allowNull: true,
    });
}
};
