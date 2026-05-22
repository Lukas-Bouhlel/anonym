const { Op } = require('sequelize');
const { RefreshToken } = require('../models');

const DEFAULT_INTERVAL_MINUTES = Number(process.env.REFRESH_TOKEN_CLEANUP_INTERVAL_MINUTES || 60);

const cleanupRefreshTokens = async () => {
    const now = new Date();
    const revokedRetentionDate = new Date(now.getTime() - (7 * 24 * 60 * 60 * 1000));

    await RefreshToken.destroy({
        where: {
            [Op.or]: [
                { expires_at: { [Op.lt]: now } },
                {
                    revoked_at: {
                        [Op.ne]: null,
                        [Op.lt]: revokedRetentionDate
                    }
                }
            ]
        }
    });
};

const startRefreshTokenCleanup = () => {
    const intervalMinutes = Number.isFinite(DEFAULT_INTERVAL_MINUTES) && DEFAULT_INTERVAL_MINUTES > 0
        ? DEFAULT_INTERVAL_MINUTES
        : 60;

    const intervalMs = intervalMinutes * 60 * 1000;

    cleanupRefreshTokens().catch((error) => {
        console.error('Initial refresh token cleanup failed:', error.message);
    });

    const timer = setInterval(() => {
        cleanupRefreshTokens().catch((error) => {
            console.error('Periodic refresh token cleanup failed:', error.message);
        });
    }, intervalMs);

    if (typeof timer.unref === 'function') {
        timer.unref();
    }

    return timer;
};

module.exports = {
    startRefreshTokenCleanup,
    cleanupRefreshTokens,
};
