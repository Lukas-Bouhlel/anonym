const { Friend, User, Inventory, Shop  } = require('../models');

/**
 * @module friendController
 * @description Ce module gère les opérations liées aux amis des utilisateurs, y compris la lecture, l'ajout, la mise à jour et la suppression des relations d'amitié.
 */

/**
 * Lire tous les amis d'un utilisateur, y compris leurs inventaires actifs.
 *
 * @async
 * @function readAll
 * @param {Object} req - L'objet de requête contenant les détails de l'utilisateur connecté.
 * @param {Object} res - L'objet de réponse.
 * @returns {Object} 200 - Liste des amis de l'utilisateur avec leurs détails et inventaires actifs.
 * @throws {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la récupération des amis.
 */
exports.readAll = async (req, res) => {
    try {
        const userId = req.auth.userId;
        const friends = await Friend.findAll({
            where: { user_id: userId },
            include: [
                {
                    model: User, // L'ami
                    as: 'FriendDetails',
                    attributes: ['id', 'username', 'email', 'avatar'], // Attributs de l'ami
                    include: [
                        {
                            model: Inventory, // Inclure l'inventaire
                            where: { active: true }, // Ne récupérer que les articles actifs
                            attributes: ['item_id', 'article_id', 'active'],
                            include: [
                                {
                                    model: Shop, // Détails de l'article
                                    attributes: ['title', 'type', 'content', 'amount']
                                }
                            ],
                            required: false // Rendre l'inventaire facultatif, récupérer même s'il n'y a pas d'articles actifs
                        }
                    ]
                }
            ]
        });

        res.status(200).json(friends);
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while retrieving friends.' });
    }
};

/**
 * Lire un ami spécifique d'un utilisateur.
 *
 * @async
 * @function read
 * @param {Object} req - L'objet de requête contenant l'ID de l'ami à lire.
 * @param {Object} res - L'objet de réponse.
 * @returns {Object} 200 - Détails de l'ami demandé.
 * @throws {Object} 404 - Non trouvé si l'ami n'existe pas.
 * @throws {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la récupération de l'ami.
 */
exports.read = async (req, res) => {
    try {
        const friendId = req.params.id;
        const friend = await Friend.findOne({
            where: { user_id: req.auth.userId, friend_id: friendId },
            include: { model: User, as: 'FriendDetails', attributes: ['id', 'username', 'email', 'avatar'] }
        });

        if (!friend) {
            return res.status(404).json({ message: "Ami non trouvé." });
        }

        res.status(200).json(friend);
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while retrieving the friend.' });
    }
};

/**
 * Ajouter un nouvel ami à la liste d'amis de l'utilisateur.
 *
 * @async
 * @function addFriend
 * @param {Object} req - L'objet de requête contenant le nom d'utilisateur de l'ami à ajouter.
 * @param {Object} res - L'objet de réponse.
 * @returns {Object} 201 - Détails de la nouvelle relation d'amitié créée.
 * @throws {Object} 404 - Non trouvé si l'utilisateur à ajouter n'existe pas.
 * @throws {Object} 400 - Mauvaise requête si l'utilisateur essaie de s'ajouter lui-même ou si la relation d'amitié existe déjà.
 * @throws {Object} 500 - Erreur interne du serveur si une erreur se produit lors de l'ajout de l'ami.
 */
exports.addFriend = async (req, res) => {
    try {
        const userId = req.auth.userId; // ID de l'utilisateur actuel
        const friendUsername = req.params.username; // Récupérer le nom d'utilisateur de l'ami à ajouter

        // Rechercher l'ami par son nom d'utilisateur
        const friend = await User.findOne({
            where: {
                username: friendUsername
            }
        });

        // Vérifier si l'utilisateur existe
        if (!friend) {
            return res.status(404).json({ message: "Utilisateur introuvable" });
        }

        const friendId = friend.id; // ID de l'ami trouvé

        // Vérifier que l'utilisateur ne s'ajoute pas lui-même en ami
        if (userId === friendId) {
            return res.status(400).json({ message: "Vous ne pouvez pas vous ajouter comme ami" });
        }

        // Vérifier si la relation d'amitié existe déjà
        const existingFriend = await Friend.findOne({
            where: {
                user_id: userId,
                friend_id: friendId
            }
        });

        if (existingFriend) {
            return res.status(400).json({ message: "Cet utilisateur est déjà votre ami" });
        }

        // Créer la relation d'amitié
        const newFriend = await Friend.create({
            user_id: userId,
            friend_id: friendId,
            status: 'ACTIVE'
        });

        res.status(201).json(newFriend);
    } catch (error) {
        res.status(500).json({ message: error.message || "An error occurred while adding the friend." });
    }
};

/**
 * Mettre à jour le statut d'une relation d'amitié.
 *
 * @async
 * @function update
 * @param {Object} req - L'objet de requête contenant l'ID de l'ami et le nouveau statut.
 * @param {Object} res - L'objet de réponse.
 * @returns {Object} 200 - La relation d'amitié mise à jour.
 * @throws {Object} 404 - Non trouvé si la relation d'amitié n'existe pas.
 * @throws {Object} 400 - Mauvaise requête si le statut est invalide.
 * @throws {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la mise à jour du statut de l'ami.
 */
exports.update = async (req, res) => {
    try {
        const friendId = req.params.id;
        const { status } = req.body;
        
        const friendship = await Friend.findOne({
            where: { user_id: req.auth.userId, friend_id: friendId }
        });

        if (!friendship) {
            return res.status(404).json({ message: "Friendship not found." });
        }

        if (status && ['ACTIVE', 'BLOQUED'].includes(status)) {
            friendship.status = status;
            await friendship.save();
            return res.status(200).json(friendship);
        } else {
            return res.status(400).json({ message: "Invalid status." });
        }
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while updating the friend status.' });
    }
};

/**
 * Supprimer une relation d'amitié.
 *
 * @async
 * @function delete
 * @param {Object} req - L'objet de requête contenant l'ID de l'ami à supprimer.
 * @param {Object} res - L'objet de réponse.
 * @returns {Object} 204 - Message de succès indiquant que la relation d'amitié a été supprimée.
 * @throws {Object} 404 - Non trouvé si la relation d'amitié n'existe pas.
 * @throws {Object} 500 - Erreur interne du serveur si une erreur se produit lors de la suppression de la relation d'amitié.
 */
exports.delete = async (req, res) => {
    try {
        const friendId = req.params.id;

        const friendship = await Friend.findOne({
            where: { user_id: req.auth.userId, friend_id: friendId }
        });

        if (!friendship) {
            return res.status(404).json({ message: "Friendship not found." });
        }

        await friendship.destroy();

        res.status(204).json({ message: "Friendship deleted successfully." });
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while deleting the friendship.' });
    }
};