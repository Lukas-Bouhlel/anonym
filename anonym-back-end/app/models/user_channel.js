'use strict';
const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class UserChannel extends Model {
        static associate(models) {
            // Vous pouvez ajouter des associations ici si nécessaire
        }
    }

    UserChannel.init({
        user_id: {
            type: DataTypes.INTEGER,
            references: {
                model: 'Users', // Modèle User
                key: 'id'
            },
            onDelete: 'CASCADE' // Supprimer les liaisons quand un utilisateur est supprimé
        },
        channel_id: {
            type: DataTypes.INTEGER,
            references: {
                model: 'Channels', // Modèle Channel
                key: 'channel_id'
            },
            onDelete: 'CASCADE'
        }
    }, {
        sequelize,
        modelName: 'UserChannel',
        tableName: 'user_channels' // Nom de la table de jonction
    });

    return UserChannel;
};