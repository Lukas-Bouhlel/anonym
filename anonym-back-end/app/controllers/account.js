const { User } = require('../models');
const bcrypt = require('bcrypt');

exports.read = async (req, res) => {
    try {
        const userId = req.auth.userId;// Récupérer l'ID de l'utilisateur depuis les paramètres JWT

        // Trouver l'utilisateur par ID avec findOne
        const user = await User.findOne({ where: { id: userId } });

        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        res.status(200).json(user);
    } catch (error) {
        res.status(500).json({ 
            message: error.message || 'Une erreur est survenue lors de la récupération des comptes.' 
        });
    }
};

exports.update = async (req, res) => {
    try {
        const userId = req.auth.userId;// Récupérer l'ID de l'utilisateur depuis les paramètres JWT
        const { username, email, password, avatar } = req.body;

        if (!userId) {
            return res.status(400).json({ message: "User ID is required." });
        }

        // Trouver l'utilisateur par ID
        const user = await User.findOne({ where: { id: userId } });

        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        // Mise à jour des informations de l'utilisateur
        if (username) user.username = username;
        if (email) user.email = email;
        if (password) user.password = await bcrypt.hash(password, 10); 
        if (avatar) user.avatar = avatar;

        await user.save();

        res.status(200).json(user);
    } catch (error) {
        res.status(500).json({ 
            message: error.message || 'Une erreur est survenue lors de la mise à jour du compte.' 
        });
    }
};

exports.delete = async (req, res) => {
    try {
        const userId = req.auth.userId;// Récupérer l'ID de l'utilisateur depuis les paramètres JWT

        if (!userId) {
            return res.status(400).json({ message: "User ID is required." });
        }

        // Trouver l'utilisateur par ID
        const user = await User.findOne({ where: { id: userId } });

        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        // Supprimer l'utilisateur
        await user.destroy();

        res.status(200).json({ message: "User deleted successfully" });
    } catch (error) {
        res.status(500).json({ 
            message: error.message || 'Une erreur est survenue lors de la suppression du compte.' 
        });
    }
};