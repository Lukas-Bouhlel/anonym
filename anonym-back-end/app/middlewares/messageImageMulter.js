const multer = require('multer');
const fs = require('fs');

const MIME_TYPES = {
    'image/jpg': 'jpg',
    'image/jpeg': 'jpg',
    'image/gif': 'gif',
    'image/png': 'png',
    'image/webp': 'webp',
    'image/svg+xml': 'svg'
};

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
        const name = file.originalname.split(' ').join('_').split('.')[0];
        const extension = MIME_TYPES[file.mimetype] || 'jpg';
        callback(null, `${name}_${Date.now()}.${extension}`);
    }
});

module.exports = multer({ storage }).single('image');
