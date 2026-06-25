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
        const folder = 'uploads/messages/images';
        createDirectory(folder);
        callback(null, folder);
    },
    filename: (req, file, callback) => {
        callback(null, createImageFileName(file));
    }
});

module.exports = multer({
    storage,
    fileFilter: imageFileFilter,
    limits: imageUploadLimits
}).single('image');
