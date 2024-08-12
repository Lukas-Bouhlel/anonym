const { v4: uuidv4 } = require('uuid');

const deviceInfoMiddleware = (req, res, next) => {
    let deviceId = req.cookies.deviceId;
    if (!deviceId) {
        deviceId = uuidv4(); // Generate a unique device ID if not already present
        res.cookie('deviceId', deviceId, { httpOnly: true, secure: process.env.NODE_ENV === 'production' });
    }

    req.deviceInfo = deviceId;
    next();
};

module.exports = deviceInfoMiddleware;