'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  up: async (queryInterface, Sequelize) => {

     // Remplacez les noms de contraintes par les noms corrects trouvés dans l'étape précédente
     await queryInterface.removeConstraint('private_messages', 'private_messages_sender_id_foreign_idx'); // Remplacez par le nom correct
     await queryInterface.removeConstraint('private_messages', 'private_messages_channel_id_foreign_idx'); // Remplacez par le nom correct
        
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
  down: async (queryInterface, Sequelize) => {
      // Optionnel : instructions pour la migration inverse
      await queryInterface.removeConstraint('private_messages', 'private_messages_channel_id_foreign_idx');
      await queryInterface.removeConstraint('private_messages', 'private_messages_sender_id_foreign_idx');
  }
};
