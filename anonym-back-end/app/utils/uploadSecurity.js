const crypto = require('crypto');
const path = require('path');
const multer = require('multer');

const ALLOWED_IMAGE_TYPES = {
    'image/jpg': 'jpg',
    'image/jpeg': 'jpg',
    'image/png': 'png',
    'image/gif': 'gif',
    'image/webp': 'webp'
};

const DEFAULT_MAX_FILE_SIZE = 5 * 1024 * 1024;

const sanitizeFileBaseName = (originalName = 'upload') => {
    const parsedName = path.parse(originalName).name || 'upload';
    return parsedName
        .normalize('NFKD')
        .replace(/[^\w-]/g, '_')
        .replace(/_+/g, '_')
        .slice(0, 60) || 'upload';
};

const createImageFileName = (file) => {
    const baseName = sanitizeFileBaseName(file.originalname);
    const extension = ALLOWED_IMAGE_TYPES[file.mimetype];
    const suffix = crypto.randomBytes(8).toString('hex');
    return `${baseName}_${Date.now()}_${suffix}.${extension}`;
};

const imageFileFilter = (req, file, callback) => {
    if (!ALLOWED_IMAGE_TYPES[file.mimetype]) {
        return callback(new multer.MulterError('LIMIT_UNEXPECTED_FILE', file.fieldname));
    }

    return callback(null, true);
};

const imageUploadLimits = {
    fileSize: Number(process.env.UPLOAD_IMAGE_MAX_BYTES || DEFAULT_MAX_FILE_SIZE),
    files: 1
};

module.exports = {
    ALLOWED_IMAGE_TYPES,
    createImageFileName,
    imageFileFilter,
    imageUploadLimits
};
