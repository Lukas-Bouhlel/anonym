const authorizeAdmin = (req, res, next) => {
    if (req.auth.userRole === 'User') {
        return res.status(403).json({ message: 'Accès interdit, vous devez être Admin.' });
    }

    next();
};

module.exports = authorizeAdmin;