'use strict';
const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class PrivateMessage extends Model {
        static associate(models) {
            // Association avec l'utilisateur (expéditeur)
            PrivateMessage.belongsTo(models.User, { foreignKey: 'sender_id' })    
            // Association avec le canal
            PrivateMessage.belongsTo(models.Channel, { foreignKey: 'channel_id' });
        }
    }

    PrivateMessage.init({
        message_id: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true
        },
        sender_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: 'users',
                key: 'id',
            }
        },
        content: {
            type: DataTypes.TEXT,
            allowNull: false
        },
        status: {
            type: DataTypes.STRING,
            allowNull: false,
            defaultValue: 'unread',  // Valeur par défaut
            validate: {
                isIn: [['unread', 'read']]  // Seulement 'unread' ou 'read' comme valeur possible
            }
        },
        channel_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: 'channels',
                key: 'channel_id'
            }
        }
    }, {
        sequelize,
        modelName: 'PrivateMessage',
        tableName: 'private_messages'
    });

    return PrivateMessage;
};