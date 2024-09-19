const { Friend, User } = require('../models');

exports.readAll = async (req, res) => {
    try {
        const friends = await Friend.findAll({
            where: { user_id: req.auth.userId },
            include: { model: User, as: 'FriendDetails', attributes: ['id', 'username', 'email', 'avatar'] }
        });

        res.status(200).json(friends);
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while retrieving friends.' });
    }
};

exports.read = async (req, res) => {
    try {
        const friendId = req.params.id;
        const friend = await Friend.findOne({
            where: { user_id: req.auth.userId, friend_id: friendId },
            include: { model: User, as: 'FriendDetails', attributes: ['id', 'username', 'email', 'avatar'] }
        });

        if (!friend) {
            return res.status(404).json({ message: "Friend not found." });
        }

        res.status(200).json(friend);
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while retrieving the friend.' });
    }
};

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
            return res.status(404).json({ message: "User not found." });
        }

        const friendId = friend.id; // ID de l'ami trouvé

        // Vérifier que l'utilisateur ne s'ajoute pas lui-même en ami
        if (userId === friendId) {
            return res.status(400).json({ message: "You cannot add yourself as a friend." });
        }

        // Vérifier si la relation d'amitié existe déjà
        const existingFriend = await Friend.findOne({
            where: {
                user_id: userId,
                friend_id: friendId
            }
        });

        if (existingFriend) {
            return res.status(400).json({ message: "Friendship already exists." });
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