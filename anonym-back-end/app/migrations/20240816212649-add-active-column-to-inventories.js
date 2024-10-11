'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up (queryInterface, Sequelize) {
    await queryInterface.addColumn('Inventories', 'active', {
      type: Sequelize.BOOLEAN,
      defaultValue: true, // Valeur par défaut si nécessaire
      allowNull: false,   // Indique que cette colonne ne peut pas être null
    });
  },

  async down (queryInterface) {
    await queryInterface.removeColumn('Inventories', 'active');
  }
};
