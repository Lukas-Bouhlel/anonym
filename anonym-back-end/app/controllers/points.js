const { User, UserPointDaily, sequelize } = require('../models');
const { Op } = require('sequelize');
const { getLevelProgress } = require('../utils/points');

const normalizeDateInput = (value, fallback) => {
  if (!value) return fallback;
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return fallback;
  return parsed.toISOString().slice(0, 10);
};

exports.getMyPointsStats = async (req, res) => {
  try {
    const userId = req.auth.userId;
    const requestedPeriod = req.query.period ? req.query.period.toLowerCase() : null;

    if (requestedPeriod && !['day', 'week', 'month'].includes(requestedPeriod)) {
      return res.status(400).json({ message: 'Le parametre period doit etre day, week ou month.' });
    }

    const today = new Date();
    const defaultStart = new Date(today);
    defaultStart.setDate(defaultStart.getDate() - 30);

    const startDate = normalizeDateInput(req.query.startDate, defaultStart.toISOString().slice(0, 10));
    const endDate = normalizeDateInput(req.query.endDate, today.toISOString().slice(0, 10));

    const user = await User.findByPk(userId, {
      attributes: ['id', 'username', 'total_points']
    });

    if (!user) {
      return res.status(404).json({ message: 'Utilisateur introuvable.' });
    }

    let period = requestedPeriod;
    if (!period) {
      const firstStat = await UserPointDaily.findOne({
        where: { user_id: userId },
        attributes: ['stat_date'],
        order: [['stat_date', 'ASC']],
        raw: true
      });

      if (!firstStat) {
        period = 'day';
      } else {
        const firstDate = new Date(firstStat.stat_date);
        const daysOfData = Math.floor((today - firstDate) / (1000 * 60 * 60 * 24)) + 1;

        if (daysOfData >= 90) {
          period = 'month';
        } else if (daysOfData >= 30) {
          period = 'week';
        } else {
          period = 'day';
        }
      }
    }

    const where = {
      user_id: userId,
      stat_date: {
        [Op.between]: [startDate, endDate]
      }
    };

    const bucketFormat = period === 'day' ? '%Y-%m-%d' : period === 'week' ? '%x-W%v' : '%Y-%m';

    const groupedRows = await UserPointDaily.findAll({
      attributes: [
        [sequelize.fn('DATE_FORMAT', sequelize.col('stat_date'), bucketFormat), 'bucket'],
        [sequelize.fn('SUM', sequelize.col('messages_count')), 'messagesCount'],
        [sequelize.fn('SUM', sequelize.col('points_earned')), 'pointsEarned']
      ],
      where,
      group: [sequelize.fn('DATE_FORMAT', sequelize.col('stat_date'), bucketFormat)],
      order: [[sequelize.fn('DATE_FORMAT', sequelize.col('stat_date'), bucketFormat), 'ASC']],
      raw: true
    });

    const totals = await UserPointDaily.findOne({
      attributes: [
        [sequelize.fn('COALESCE', sequelize.fn('SUM', sequelize.col('messages_count')), 0), 'messagesCount'],
        [sequelize.fn('COALESCE', sequelize.fn('SUM', sequelize.col('points_earned')), 0), 'pointsEarned']
      ],
      where,
      raw: true
    });

    const level = getLevelProgress(user.total_points || 0);

    return res.status(200).json({
      period,
      periodSelection: requestedPeriod ? 'manual' : 'auto',
      range: { startDate, endDate },
      user: {
        id: user.id,
        username: user.username,
        totalPoints: user.total_points || 0,
        level
      },
      totals: {
        messagesCount: Number(totals?.messagesCount || 0),
        pointsEarned: Number(totals?.pointsEarned || 0)
      },
      history: groupedRows.map((row) => ({
        bucket: row.bucket,
        messagesCount: Number(row.messagesCount || 0),
        pointsEarned: Number(row.pointsEarned || 0)
      }))
    });
  } catch (error) {
    return res.status(500).json({ message: error.message || 'Une erreur est survenue lors de la recuperation des points.' });
  }
};
