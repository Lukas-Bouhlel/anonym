const { Shop } = require('../models');
const fs = require('fs');

/**
 * @module shopController
 * @description Ce module contient des fonctions pour gérer les articles dans la boutique, y compris la création, la lecture, la mise à jour et la suppression d'articles.
 */

/**
 * Lister tous les articles.
 *
 * @async
 * @function readAll
 * @param {Object} req - L'objet de requête.
 * @param {Object} res - L'objet de réponse.
 * @returns {Object} 200 - Liste des articles de la boutique.
 * @returns {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la récupération des articles.
 */
exports.readAll = async (req, res) => {
    try {
        const shopItems  = await Shop.findAll();
        res.status(200).json(shopItems);
    } catch (error) {
        res.status(500).json({ message: error.message || "An error occurred while retrieving the shop." });
    }
};

/**
 * Lire un article spécifique par ID.
 *
 * @async
 * @function read
 * @param {Object} req - L'objet de requête.
 * @param {Object} res - L'objet de réponse.
 * @throws {Object} 404 - Non trouvé si l'article de la boutique n'existe pas.
 * @returns {Object} 200 - L'article de la boutique demandé.
 * @returns {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la récupération de l'article.
 */
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

/**
 * Créer un nouvel article.
 *
 * @async
 * @function create
 * @param {Object} req - L'objet de requête.
 * @param {Object} res - L'objet de réponse.
 * @throws {Object} 403 - Interdit si l'utilisateur n'a pas la permission de créer un article.
 * @throws {Object} 400 - Mauvaise requête si des champs requis sont manquants ou invalides.
 * @returns {Object} 201 - L'article de la boutique créé.
 * @returns {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la création de l'article.
 */
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

/**
 * Mettre à jour un article spécifique par ID.
 *
 * @async
 * @function update
 * @param {Object} req - L'objet de requête.
 * @param {Object} res - L'objet de réponse.
 * @throws {Object} 403 - Interdit si l'utilisateur n'a pas la permission de mettre à jour l'article.
 * @throws {Object} 404 - Non trouvé si l'article de la boutique n'existe pas.
 * @throws {Object} 400 - Mauvaise requête si des champs requis sont invalides.
 * @returns {Object} 201 - L'article de la boutique mis à jour.
 * @returns {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la mise à jour de l'article.
 */
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

/**
 * Supprimer un article spécifique par ID.
 *
 * @async
 * @function delete
 * @param {Object} req - L'objet de requête.
 * @param {Object} res - L'objet de réponse.
 * @throws {Object} 403 - Interdit si l'utilisateur n'a pas la permission de supprimer un article.
 * @throws {Object} 404 - Non trouvé si l'article de la boutique n'existe pas.
 * @returns {Object} 204 - Aucune content, indique que l'article a été supprimé.
 * @returns {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la suppression de l'article.
 */
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