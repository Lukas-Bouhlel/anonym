'use strict';
const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
  class RefreshToken extends Model {
    static associate(models) {
      RefreshToken.belongsTo(models.User, { foreignKey: 'user_id', as: 'user' });
    }
  }

  RefreshToken.init({
    user_id: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    token_hash: {
      type: DataTypes.STRING(128),
      allowNull: false,
      unique: true
    },
    expires_at: {
      type: DataTypes.DATE,
      allowNull: false
    },
    revoked_at: {
      type: DataTypes.DATE,
      allowNull: true
    },
    created_by_ip: {
      type: DataTypes.STRING,
      allowNull: true
    },
    user_agent: {
      type: DataTypes.STRING,
      allowNull: true
    },
    last_used_at: {
      type: DataTypes.DATE,
      allowNull: true
    }
  }, {
    sequelize,
    modelName: 'RefreshToken',
    tableName: 'refresh_tokens'
  });

  return RefreshToken;
};
