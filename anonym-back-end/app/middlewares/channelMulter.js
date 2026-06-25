const multer = require('multer');
const fs = require('fs');
const {
    createImageFileName,
    imageFileFilter,
    imageUploadLimits
} = require('../utils/uploadSecurity');

const createDirectory = (dir) => {
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }
};

const storage = multer.diskStorage({
    destination: (req, file, callback) => {
        const folder = 'uploads/channels/covers';
        createDirectory(folder);
        callback(null, folder);
    },
    filename: (req, file, callback) => {
        callback(null, createImageFileName(file));
    }
});

const upload = multer({
    storage,
    fileFilter: imageFileFilter,
    limits: imageUploadLimits
}).fields([
    { name: 'cover_image', maxCount: 1 },
    { name: 'image', maxCount: 1 }
]);

module.exports = (req, res, next) => {
    upload(req, res, (err) => {
        if (err) return next(err);

        const coverFromCoverImage = req.files?.cover_image?.[0];
        const coverFromImage = req.files?.image?.[0];
        req.file = coverFromCoverImage || coverFromImage || null;
        return next();
    });
};
