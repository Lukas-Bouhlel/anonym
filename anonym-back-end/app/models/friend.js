'use strict';
const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class Friend extends Model {
        static associate(models) {
            // Association avec l'utilisateur (celui qui envoie la demande)
            Friend.belongsTo(models.User, { foreignKey: 'user_id', as: 'User' });
            // Association avec l'utilisateur (l'ami)
            Friend.belongsTo(models.User, { foreignKey: 'friend_id', as: 'FriendDetails' });
        }
    }

    Friend.init({
        id: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true
        },
        user_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: 'users', // nom de la table users
                key: 'id'
            }
        },
        friend_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: 'users', // nom de la table users
                key: 'id'
            }
        },
        status: {
            type: DataTypes.ENUM('ACTIVE', 'PENDING', 'BLOQUED'),
            allowNull: false,
            defaultValue: 'PENDING'
        }
    }, {
        sequelize,
        modelName: 'Friend',
        tableName: 'friends',
        timestamps: true
    });

    return Friend;
};
