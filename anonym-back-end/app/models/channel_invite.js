'use strict';
const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
    class ChannelInvite extends Model {
        static associate(models) {
            ChannelInvite.belongsTo(models.Channel, { foreignKey: 'channel_id' });
            ChannelInvite.belongsTo(models.User, { foreignKey: 'created_by', as: 'creator' });
        }
    }

    ChannelInvite.init({
        invite_id: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true
        },
        channel_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: 'channels',
                key: 'channel_id'
            }
        },
        code: {
            type: DataTypes.STRING(64),
            allowNull: false,
            unique: true
        },
        created_by: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: 'users',
                key: 'id'
            }
        },
        expires_at: {
            type: DataTypes.DATE,
            allowNull: true
        },
        max_uses: {
            type: DataTypes.INTEGER,
            allowNull: true
        },
        uses_count: {
            type: DataTypes.INTEGER,
            allowNull: false,
            defaultValue: 0
        },
        is_active: {
            type: DataTypes.BOOLEAN,
            allowNull: false,
            defaultValue: true
        }
    }, {
        sequelize,
        modelName: 'ChannelInvite',
        tableName: 'channel_invites'
    });

    return ChannelInvite;
};
