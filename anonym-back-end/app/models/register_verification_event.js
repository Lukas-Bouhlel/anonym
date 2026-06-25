'use strict';
const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
  class RegisterVerificationEvent extends Model {
    static associate() {}
  }

  RegisterVerificationEvent.init({
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true
    },
    email: {
      type: DataTypes.STRING,
      allowNull: false
    },
    ip: {
      type: DataTypes.STRING(64),
      allowNull: false
    },
    event_type: {
      type: DataTypes.ENUM('REQUEST_CODE'),
      allowNull: false
    }
  }, {
    sequelize,
    modelName: 'RegisterVerificationEvent',
    tableName: 'register_verification_events'
  });

  return RegisterVerificationEvent;
};
