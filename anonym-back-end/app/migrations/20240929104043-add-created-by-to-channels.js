'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up (queryInterface, Sequelize) {
    await queryInterface.addColumn('channels', 'created_by', {
      type: Sequelize.INTEGER,
      allowNull: false,
    });

    await queryInterface.addConstraint('channels', {
        fields: ['created_by'],
        type: 'foreign key',
        name: 'channels_created_by_fk',
        references: {
            table: 'users',
            field: 'id',
        },
        onDelete: 'CASCADE',  // Si l'utilisateur est supprimé, supprimer le canal
        onUpdate: 'CASCADE',
    });
  },

  async down (queryInterface) {
    await queryInterface.removeConstraint('channels', 'channels_created_by_fk');
    await queryInterface.removeColumn('channels', 'created_by');
  }
};
