'use strict';
const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
  class Invoice extends Model {
    static associate(models) {
      // Define association here
      this.belongsTo(models.User, { foreignKey: 'user_id' });
      this.belongsTo(models.Shop, { foreignKey: 'article_id' });
    }
  }

  Invoice.init({
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true
    },
    user_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'Users',
        key: 'id'
      }
    },
    article_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'Shops',
        key: 'article_id'
      }
    },
    type: {
      type: DataTypes.ENUM('SUBSCRIPTION', 'COLOR', 'CADRE'), // Replace with your actual types
      allowNull: false
    },
    amount: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    content: {
      type: DataTypes.STRING,
      allowNull: false
    },
    quantity: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 1
    }
  }, {
    sequelize,
    modelName: 'Invoice',
  });

  return Invoice;
};
