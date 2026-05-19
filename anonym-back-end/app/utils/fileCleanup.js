const fs = require('fs');
const path = require('path');

const uploadsRoot = path.resolve(__dirname, '../../uploads');

const extractUploadsRelativePath = (value) => {
    if (!value || typeof value !== 'string') return null;

    const marker = '/uploads/';
    const markerIndex = value.indexOf(marker);
    if (markerIndex !== -1) {
        return value.slice(markerIndex + marker.length).replace(/\//g, path.sep);
    }

    if (value.startsWith('uploads/')) {
        return value.slice('uploads/'.length).replace(/\//g, path.sep);
    }

    return null;
};

const resolveUploadPath = (value) => {
    const relativePath = extractUploadsRelativePath(value);
    if (!relativePath) return null;

    const absolutePath = path.resolve(uploadsRoot, relativePath);
    if (!absolutePath.startsWith(uploadsRoot)) {
        return null;
    }

    return absolutePath;
};

const deleteUploadFileIfExists = (value) => {
    const absolutePath = resolveUploadPath(value);
    if (!absolutePath) return false;
    if (!fs.existsSync(absolutePath)) return false;

    try {
        fs.unlinkSync(absolutePath);
        return true;
    } catch (error) {
        console.error(`Error deleting file ${absolutePath}:`, error.message);
        return false;
    }
};

const deleteUploadFiles = (values) => {
    if (!Array.isArray(values)) return 0;
    const uniqueValues = Array.from(new Set(values.filter(Boolean)));
    let deletedCount = 0;

    for (const value of uniqueValues) {
        if (deleteUploadFileIfExists(value)) {
            deletedCount += 1;
        }
    }

    return deletedCount;
};

module.exports = {
    deleteUploadFileIfExists,
    deleteUploadFiles
};
