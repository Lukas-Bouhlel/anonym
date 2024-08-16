'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up (queryInterface, Sequelize) {
    await queryInterface.addColumn('inventories', 'active', {
      type: Sequelize.BOOLEAN,
      defaultValue: true, // Valeur par défaut si nécessaire
      allowNull: false,   // Indique que cette colonne ne peut pas être null
    });
  },

  async down (queryInterface, Sequelize) {
    await queryInterface.removeColumn('inventories', 'active');
  }
};
