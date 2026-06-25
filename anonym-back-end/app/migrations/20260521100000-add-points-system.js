'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn('users', 'total_points', {
      type: Sequelize.INTEGER,
      allowNull: false,
      defaultValue: 0
    });

    await queryInterface.addColumn('shop', 'points_multiplier', {
      type: Sequelize.DECIMAL(5, 2),
      allowNull: false,
      defaultValue: 1.0
    });

    await queryInterface.createTable('user_point_daily', {
      user_point_daily_id: {
        type: Sequelize.INTEGER,
        autoIncrement: true,
        primaryKey: true,
        allowNull: false
      },
      user_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'users',
          key: 'id'
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE'
      },
      stat_date: {
        type: Sequelize.DATEONLY,
        allowNull: false
      },
      messages_count: {
        type: Sequelize.INTEGER,
        allowNull: false,
        defaultValue: 0
      },
      points_earned: {
        type: Sequelize.INTEGER,
        allowNull: false,
        defaultValue: 0
      },
      createdAt: {
        allowNull: false,
        type: Sequelize.DATE
      },
      updatedAt: {
        allowNull: false,
        type: Sequelize.DATE
      }
    });

    await queryInterface.addIndex('user_point_daily', ['user_id', 'stat_date'], {
      unique: true,
      name: 'user_point_daily_user_id_stat_date_unique'
    });
  },

  async down(queryInterface) {
    await queryInterface.removeIndex('user_point_daily', 'user_point_daily_user_id_stat_date_unique');
    await queryInterface.dropTable('user_point_daily');
    await queryInterface.removeColumn('shop', 'points_multiplier');
    await queryInterface.removeColumn('users', 'total_points');
  }
};
