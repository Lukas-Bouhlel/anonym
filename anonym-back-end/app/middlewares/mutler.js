const multer = require("multer");
const fs = require('fs');

//On définit les extensions selon le mime type.
const MIME_TYPES = {
"image/jpg" : "jpg",
"image/jpeg" : "jpg",
"image/gif" : "gif",
"image/png" : "png",
"image/webp" : "webp",
};

//On crée le dossier uploads s'il n'existe pas
if (!fs.existsSync('uploads')) {
    fs.mkdirSync('uploads');
}

// diskStorage => destination du fichier / générer un nom de fichier unique
const storage = multer.diskStorage({
destination: (req, file, callback) => {
    callback(null, "uploads");
},
filename: (req, file, callback) => {
const name = file.originalname.split(" ").join("_").split(".")[0]
const extension = MIME_TYPES[file.mimetype]
callback(null, name + "_" + Date.now() + "." + extension);
},
});

// On exporte le module avec ces paramètres en précisant
// qu'on attend un champ "image"
module.exports = multer({storage: storage}).single("image");