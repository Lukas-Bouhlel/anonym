const multer = require("multer");
const fs = require('fs');

//On définit les extensions selon le mime type.
const MIME_TYPES = {
"image/jpg" : "jpg",
"image/jpeg" : "jpg",
"image/gif" : "gif",
"image/png" : "png",
"image/webp" : "webp",
"image/svg+xml": "svg"
};

//On crée le dossier uploads s'il n'existe pas
if (!fs.existsSync('uploads')) {
    fs.mkdirSync('uploads');
}

// On crée dynamiquement le dossier uploads s'il n'existe pas
const createDirectory = (dir) => {
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
  };

// diskStorage => destination du fichier / générer un nom de fichier unique
const storage = multer.diskStorage({
    destination: (req, file, callback) => {
        // Détecter le contexte de la route pour déterminer le dossier
        let folder = 'uploads';  // dossier par défaut
    
        if (req.baseUrl.includes('/shop')) {
          folder = 'uploads/articles';
        }

        if (req.baseUrl.includes('/auth') || req.baseUrl.includes('/account') || req.baseUrl.includes('/admin')) {
            folder = 'uploads/profiles/avatars';
        }

        createDirectory(folder);  // créer le dossier si nécessaire
        callback(null, folder);
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