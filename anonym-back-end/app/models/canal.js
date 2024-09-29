'use strict';
const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class Channel extends Model {
        static associate(models) {
            // Relation many-to-many avec User via la table de jonction UserChannel
            Channel.belongsToMany(models.User, { through: 'UserChannel', foreignKey: 'channel_id' });
            // Un canal peut avoir plusieurs messages
            Channel.hasMany(models.PrivateMessage, {
                foreignKey: 'channel_id',
                onDelete: 'CASCADE', // Ajoutez cette ligne pour activer la suppression en cascade
            });
            // Association avec User pour le créateur du canal
            Channel.belongsTo(models.User, { foreignKey: 'created_by', as: 'creator' }); // Nouvelle association pour le créateur
        }
    }

    Channel.init({
        channel_id: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true
        },
        name: {
            type: DataTypes.STRING, // Facultatif, au cas où vous voulez nommer les canaux
            allowNull: true
        },
        description: {
            type: DataTypes.STRING, // Facultatif, une description pour le canal
            allowNull: true
        },
        created_by: {
            type: DataTypes.INTEGER,
            allowNull: false, // Rendre obligatoire
            references: {
                model: 'users',
                key: 'id'
            }
        }
    }, {
        sequelize,
        modelName: 'Channel',
        tableName: 'channels'
    });

    return Channel;
};