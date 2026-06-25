'use strict';
const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
  class Shop extends Model {
    /**
     * Helper method for defining associations.
     * This method is not a part of Sequelize lifecycle.
     * The `models/index` file will call this method automatically.
     */
    static associate() {
      // define association here if needed in the future
    }
  }

  Shop.init({
    article_id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
      allowNull: false
    },
    amount: {
      type: DataTypes.INTEGER,
      allowNull: false,
      validate: {
        isInt: {
          msg: 'Amount must be an integer.'
        }
      }
    },
    timestamp: {
      type: DataTypes.DATE,
      allowNull: true,
    },
    title: {
      type: DataTypes.STRING,
      allowNull: false,
      validate: {
        notEmpty: {
          msg: 'Title cannot be empty.'
        }
      }
    },
    type: {
      type: DataTypes.ENUM('SUBSCRIPTION', 'COLOR', 'CADRE'),
      allowNull: false,
      validate: {
        isIn: {
          args: [['SUBSCRIPTION', 'COLOR', 'CADRE']],
          msg: 'Type must be either SUBSCRIPTION, COLOR, or CADRE.'
        }
      }
    },
    content: {
      type: DataTypes.STRING,
      allowNull: false,
      validate: {
        notEmpty: {
          msg: 'Content cannot be empty.'
        }
      }
    },
    points_multiplier: {
      type: DataTypes.DECIMAL(5, 2),
      allowNull: false,
      defaultValue: 1.0,
      validate: {
        min: 1
      }
    }
  }, {
    sequelize,
    modelName: 'Shop',
    tableName: 'shop',
  });

  return Shop;
};
