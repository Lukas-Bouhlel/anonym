'use strict';
const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
  class Inventory extends Model {
    static associate(models) {
      // Association avec l'utilisateur
      Inventory.belongsTo(models.User, { foreignKey: 'user_id' });
      // Association avec l'article
      Inventory.belongsTo(models.Shop, { foreignKey: 'article_id' });
    }
  }

  Inventory.init({
    item_id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    user_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    article_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    active: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
      allowNull: false
    }
  }, {
    sequelize,
    modelName: 'Inventory',
    indexes: [
        {
          unique: true,
          fields: ['user_id', 'article_id']
        }
      ]
  });

  return Inventory;
};