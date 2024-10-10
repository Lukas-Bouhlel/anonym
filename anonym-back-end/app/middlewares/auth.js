const jwt = require('jsonwebtoken');

module.exports = (req, res, next) => {
    try {
        const token = req.cookies.token; 

        const decodedToken = jwt.verify(token, process.env.JWT_SECRET);
        const userId = decodedToken.userId;
        const userRole = decodedToken.userRole;

        req.auth = {
            userId,
            userRole
        };
        
        next();
    } catch (error) {
        res.status(401).json({
            error: 'Unauthorized request!'
        });
    }
};