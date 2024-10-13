'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  up: async (queryInterface) => {
      // Vérifier si la contrainte existe avant de la supprimer
      const [constraints] = await queryInterface.sequelize.query(`
        SELECT CONSTRAINT_NAME 
        FROM information_schema.KEY_COLUMN_USAGE 
        WHERE TABLE_NAME = 'private_messages' 
      `);

      // Supprimer les contraintes seulement si elles existent
      const constraintNames = constraints.map(row => row.CONSTRAINT_NAME);

      if (constraintNames.includes('private_messages_sender_id_foreign_idx')) {
          await queryInterface.removeConstraint('private_messages', 'private_messages_sender_id_foreign_idx');
      }

      if (constraintNames.includes('private_messages_channel_id_foreign_idx')) {
          await queryInterface.removeConstraint('private_messages', 'private_messages_channel_id_foreign_idx');
      }

      // Ajouter la contrainte de clé étrangère avec ON DELETE CASCADE pour channel_id
      await queryInterface.addConstraint('private_messages', {
          fields: ['channel_id'],
          type: 'foreign key',
          name: 'private_messages_channel_id_foreign_idx',
          references: {
              table: 'channels',
              field: 'channel_id',
          },
          onDelete: 'CASCADE', // Ajouter la contrainte de suppression en cascade
      });

      // Ajouter la contrainte de clé étrangère avec ON DELETE CASCADE pour sender_id
      await queryInterface.addConstraint('private_messages', {
          fields: ['sender_id'],
          type: 'foreign key',
          name: 'private_messages_sender_id_foreign_idx',
          references: {
              table: 'users',
              field: 'id',
          },
          onDelete: 'CASCADE', // Ajouter la contrainte de suppression en cascade
      });
  },
  down: async (queryInterface) => {
      // Supprimer les contraintes si elles existent
      const [constraints] = await queryInterface.sequelize.query(`
        SELECT CONSTRAINT_NAME 
        FROM information_schema.KEY_COLUMN_USAGE 
        WHERE TABLE_NAME = 'private_messages'
      `);

      const constraintNames = constraints.map(row => row.CONSTRAINT_NAME);

      if (constraintNames.includes('private_messages_sender_id_foreign_idx')) {
          await queryInterface.removeConstraint('private_messages', 'private_messages_sender_id_foreign_idx');
      }

      if (constraintNames.includes('private_messages_channel_id_foreign_idx')) {
          await queryInterface.removeConstraint('private_messages', 'private_messages_channel_id_foreign_idx');
      }
  }
};