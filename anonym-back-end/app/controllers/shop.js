const { Shop } = require('../models');
const fs = require('fs');

// Lister tous les articles
exports.readAll = async (req, res) => {
    try {
        const shopItems  = await Shop.findAll();
        res.status(200).json(shopItems);
    } catch (error) {
        res.status(500).json({ message: error.message || "An error occurred while retrieving the shop." });
    }
};

// Lire un article spécifique par ID
exports.read = async (req, res) => {
    try {
        const shopItem  = await Shop.findByPk(req.params.id);
        if (!shopItem ) {
            return res.status(404).json({ message: "Shop item not found." });
        }
        res.status(200).json(shopItem);
    } catch (error) {
        res.status(500).json({ message: error.message || "An error occurred while retrieving the shop item." });
    }
};

// Créer un nouvel article
exports.create = async (req, res) => {
    try {
        if (req.auth.userRole === 'USER') {
            return res.status(403).json({ message: "You do not have permission to create an article." });
        }

        if(!req.file) {
            return res.status(400).json({ message: "L'image' de l'article est obligatoires" });
        }

        const { title, amount, type } = JSON.parse(req.body.datas);
        if (!title) {
            return res.status(400).json({ message: "Le titre de l'article est obligatoires" });
        } else if(!amount) {
            return res.status(400).json({ message: "Le montant de l'article est obligatoires" });
        }else if (!type) {
            return res.status(400).json({ message: "Le type de l'article est obligatoires" });
        }
        
        const pathname = `${req.protocol}://${req.get("host")}/uploads/articles/${req.file.filename}`;

        if (!pathname) {
            return res.status(400).json({ message: "Pathname are required." });
        }

        const newArticle = await Shop.create({
            ...JSON.parse(req.body.datas),
            content: pathname,
        });

        res.status(201).json(newArticle);
    } catch (error) {
        res.status(500).json({ message: error.message || "An error occurred while creating the shop item." });
    }
};

// Mettre à jour un article spécifique par ID
exports.update = async (req, res) => {
    try {
        // Vérifier que l'utilisateur est soit ADMIN, soit SUPER_ADMIN
        if (req.auth.userRole === 'USER') {
            return res.status(403).json({ message: "You do not have permission to create a article." });
        }

        let shop = await Shop.findByPk(req.params.id);
        if (!shop) {
            return res.status(404).json({ message: "Shop item not found." });
        }

        let updateArticle = { ...JSON.parse(req.body.datas) }
        
        if (req.file) {
            const pathname = `${req.protocol}://${req.get("host")}/uploads/articles/${req.file.filename}`;

            updateArticle = {
                ...updateArticle,
                content: pathname
            };

            if (shop.content) {
                const filename = shop.content.split("/uploads/articles/")[1];
                fs.unlink(`uploads/articles/${filename}`, (err) => {
                    if (err) {
                        console.error(`Error deleting image ${filename}: ${err.message}`);
                    } else {
                        console.log(`Image ${filename} deleted`);
                    }
                });
            }
        }

        await shop.update(updateArticle);

        res.status(201).json(shop);
    } catch (error) {
        res.status(500).json({ message: error.message || "An error occurred while updating the shop item." });
    }
};

// Supprimer un article spécifique par ID
exports.delete = async (req, res) => {
    try {
        // Vérifier que l'utilisateur est soit ADMIN, soit SUPER_ADMIN
        if (req.auth.userRole === 'USER') {
            return res.status(403).json({ message: "You do not have permission to create a article." });
        }

        let shop = await Shop.findByPk(req.params.id);
        if (!shop) {
            return res.status(404).json({ message: "Shop item not found." });
        }

        if (shop.content) {
            const filename = shop.content.split("/uploads/articles/")[1];
            fs.unlink(`uploads/articles/${filename}`, (err) => {
                if (err) {
                    console.error(`Error deleting image ${filename}: ${err.message}`);
                } else {
                    console.log(`Image ${filename} deleted`);
                }
            });
        }

        await shop.destroy(shop);

        res.status(204).send();
    } catch (error) {
        res.status(500).json({ message: error.message || "An error occurred while deleting the shop item." });
    }
};