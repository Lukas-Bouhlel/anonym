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
      User.hasMany(models.Inventory, { foreignKey: 'user_id' });
      User.belongsToMany(models.Channel, { through: 'UserChannel', foreignKey: 'user_id' });
    }
  }
  User.init({
    username: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: {
        args: true,
        msg: "Ce nom d'utilisateur est déjà utilisé"
      },
      validate: {
        notNull: {
          msg: "Le nom d'utilisateur est requis"
        },
        isValidUsername(value) {
          const usernameRegex = /^(?=.*[A-Za-z])([A-Za-z0-9_-]{3,15})$/;
          if (!usernameRegex.test(value)) {
            throw new Error("Nom d'utilisateur : 3 à 15 caractères, min une lettre, et peut contenir chiffres et tirets");
          }
        }
      }
    },
    email: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: {
        args: true,
        msg: "L'adresse email est déjà utilisé"
      },
      required: [true, "L'adresse email est requise"],
      trim: true,
      lowercase: true,
      validate: {
        isEmail: {
          msg: "L'e-mail doit être dans un format correct"
        },
        notNull: {
          msg: "L'adresse email est requise"
        },
        notEmpty: {
          msg: "L'adresse email est requise"
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
      required: [true, 'Le mot de passe est requis'],
      validate: {
        notNull: {
          msg: "Le mot de passe est requis"
        },
        notEmpty: {
          msg: "Le mot de passe est requis"
        },
        isValidPassword(value) {
          const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+=\-\[\]{};:,.<>?/\\|`~"'£¤§µ¢₹])[A-Za-z\d!@#$%^&*()_+=\-\[\]{};:,.<>?/\\|`~"'£¤§µ¢₹]{12,}$/;
          if (!passwordRegex.test(value)) {
              throw new Error("Mot de passe : 12 caractères min, majuscules, minuscules, chiffres et caractères spéciaux");
          }
        }
      }
    },
    avatar: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    roles: {
      type: DataTypes.ENUM('USER', 'ADMIN', 'SUPER_ADMIN'),
      allowNull: false,
      defaultValue: 'USER'
    },
    resetPasswordToken: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    resetPasswordExpires: {
        type: DataTypes.DATE,
        allowNull: true,
    },
  }, {
    sequelize,
    modelName: 'User',
    hooks: {
      beforeCreate: async (user, options) => {
        // Normalize the email
        user.email = normalizeEmail(user.email);

        if (user.password) {
          user.password = await bcrypt.hash(user.password, 10);
        }
        if (user.changed('username')) {
          const existingUser = await User.findOne({ where: { username: user.username } });
          if (existingUser) {
            throw new Error("Ce nom d'utilisateur est déjà utilisé");
          }
        }
        if (user.changed('email')) {
          const existingEmail = await User.findOne({ where: { email: user.email } });
          if (existingEmail) {
            throw new Error("L'adresse email est déjà utilisé");
          }
        }
      },
    }
  });

  // Function to normalize Gmail addresses
  function normalizeEmail(email) {
    const [localPart, domainPart] = email.split('@');
    if (domainPart.toLowerCase() === 'gmail.com') {
      return localPart.replace(/\./g, '') + '@' + domainPart;
    }
    return email;
  }
  return User;
};