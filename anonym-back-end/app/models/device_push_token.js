'use strict';
const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class DevicePushToken extends Model {
        static associate(models) {
            DevicePushToken.belongsTo(models.User, { foreignKey: 'user_id' });
        }
    }

    DevicePushToken.init({
        id: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true
        },
        user_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: 'users',
                key: 'id'
            }
        },
        token: {
            type: DataTypes.STRING(512),
            allowNull: false,
            unique: true
        },
        platform: {
            type: DataTypes.ENUM('android', 'ios', 'web'),
            allowNull: false
        },
        is_active: {
            type: DataTypes.BOOLEAN,
            allowNull: false,
            defaultValue: true
        }
    }, {
        sequelize,
        modelName: 'DevicePushToken',
        tableName: 'device_push_tokens',
        timestamps: true
    });

    return DevicePushToken;
};
