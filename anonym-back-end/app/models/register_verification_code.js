'use strict';
const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
  class RegisterVerificationCode extends Model {
    static associate() {}
  }

  RegisterVerificationCode.init({
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true
    },
    email: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true
    },
    code_hash: {
      type: DataTypes.STRING(64),
      allowNull: false
    },
    pending_username: {
      type: DataTypes.STRING,
      allowNull: true
    },
    pending_password_hash: {
      type: DataTypes.STRING,
      allowNull: true
    },
    code_expires_at: {
      type: DataTypes.DATE,
      allowNull: false
    },
    last_sent_at: {
      type: DataTypes.DATE,
      allowNull: true
    },
    send_attempts: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0
    },
    send_window_started_at: {
      type: DataTypes.DATE,
      allowNull: true
    },
    verify_attempts: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0
    },
    blocked_until: {
      type: DataTypes.DATE,
      allowNull: true
    },
    last_ip: {
      type: DataTypes.STRING(64),
      allowNull: true
    }
  }, {
    sequelize,
    modelName: 'RegisterVerificationCode',
    tableName: 'register_verification_codes'
  });

  return RegisterVerificationCode;
};
