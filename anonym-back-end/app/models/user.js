'use strict';
const { Model } = require('sequelize');
const bcrypt = require('bcrypt');

module.exports = (sequelize, DataTypes) => {
  class User extends Model {
    /**
     * Helper method for defining associations.
     * This method is not a part of Sequelize lifecycle.
     * The `models/index` file will call this method automatically.
     */
    static associate(models) {
      // define association here
    }
  }
  User.init({
    username: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: {
        args: true,
        msg: "This username is already in use."
      },
      validate: {
        notNull: {
          msg: "Username is required."
        }
      }
    },
    email: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: {
        args: true,
        msg: "This email is already in use."
      },
      required: [true, "L'e-mail est requise."],
      trim: true,
      lowercase: true,
      validate: {
        isEmail: {
          msg: "The email must be in the correct format."
        },
        notNull: {
          msg: "Email is required."
        },
        notEmpty: {
          msg: "Email cannot be empty."
        },
        isValidEmail: function(value) {
          const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
          if (!emailRegex.test(value)) {
            throw new Error("Le format de l'email est invalide !");
          }
        }
      }
    },
    password: {
      type: DataTypes.STRING,
      allowNull: false,
      required: [true, 'Le mot de passe est requis.'],
      validate: {
        notNull: {
          msg: "Password is required."
        },
        notEmpty: {
          msg: "Password cannot be empty."
        }
      }
    },
    avatar: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    ip_address: {
      type: DataTypes.STRING,
      allowNull: false,
    }
  }, {
    sequelize,
    modelName: 'User',
    hooks: {
      beforeCreate: async (user, options) => {
        if (user.password) {
          user.password = await bcrypt.hash(user.password, 10);
        }
        if (user.changed('username')) {
          const existingUser = await User.findOne({ where: { username: user.username } });
          if (existingUser) {
            throw new Error('This username is already in use.');
          }
        }
        if (user.changed('email')) {
          const existingEmail = await User.findOne({ where: { email: user.email } });
          if (existingEmail) {
            throw new Error('This email is already in use.');
          }
        }
      },
    }
  });
  return User;
};