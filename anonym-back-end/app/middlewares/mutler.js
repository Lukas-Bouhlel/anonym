const multer = require('multer');
const fs = require('fs');
const {
    createImageFileName,
    imageFileFilter,
    imageUploadLimits
} = require('../utils/uploadSecurity');

if (!fs.existsSync('uploads')) {
    fs.mkdirSync('uploads');
}

const createDirectory = (dir) => {
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }
};

const storage = multer.diskStorage({
    destination: (req, file, callback) => {
        let folder = 'uploads';

        if (req.baseUrl.includes('/shop')) {
            folder = 'uploads/articles';
        }

        if (req.baseUrl.includes('/auth') || req.baseUrl.includes('/account') || req.baseUrl.includes('/admin')) {
            folder = 'uploads/profiles/avatars';
        }

        if (req.baseUrl.includes('/channels')) {
            folder = 'uploads/channels/covers';
        }

        createDirectory(folder);
        callback(null, folder);
    },
    filename: (req, file, callback) => {
        callback(null, createImageFileName(file));
    },
});

module.exports = multer({
    storage,
    fileFilter: imageFileFilter,
    limits: imageUploadLimits
}).single('image');
