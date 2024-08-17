'use strict';
const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class PrivateMessage extends Model {
        static associate(models) {
            // Association avec l'utilisateur (expéditeur)
            PrivateMessage.belongsTo(models.User, { as: 'Sender', foreignKey: 'sender_id' });
            // Association avec l'utilisateur (destinataire)
            PrivateMessage.belongsTo(models.User, { as: 'Receiver', foreignKey: 'receiver_id' });
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
                key: 'id'
            }
        },
        receiver_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: 'users',
                key: 'id'
            }
        },
        content: {
            type: DataTypes.TEXT,
            allowNull: false
        }
    }, {
        sequelize,
        modelName: 'PrivateMessage',
        tableName: 'private_messages'
    });

    return PrivateMessage;
};