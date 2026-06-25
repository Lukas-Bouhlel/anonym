'use strict';
const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
  class UserPointDaily extends Model {
    static associate(models) {
      UserPointDaily.belongsTo(models.User, { foreignKey: 'user_id' });
    }
  }

  UserPointDaily.init({
    user_point_daily_id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true
    },
    user_id: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    stat_date: {
      type: DataTypes.DATEONLY,
      allowNull: false
    },
    messages_count: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0
    },
    points_earned: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0
    }
  }, {
    sequelize,
    modelName: 'UserPointDaily',
    tableName: 'user_point_daily',
    indexes: [
      {
        unique: true,
        fields: ['user_id', 'stat_date']
      }
    ]
  });

  return UserPointDaily;
};
