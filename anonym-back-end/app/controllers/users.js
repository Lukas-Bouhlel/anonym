const { User } = require('../models');
const bcrypt = require('bcrypt');

exports.readAll = async (req, res) => {
    try {
        const users = await User.findAll();

        if (req.auth.userRole === 'USER') {
            return res.status(403).json({ message: "Il faut être admin pour accéder à cette page." });
        }

        if (!users) {
            return res.status(404).json({ message: "Users not found" });
        }

        res.status(200).json(users);
    } catch (error) {
        res.status(500).json({ 
            message: error.message || 'Une erreur est survenue lors de la récupération des comptes.' 
        });
    }
};

exports.create = async (req, res) => {
    try {
        const { username, email, password, avatar, roles } = req.body;

        // Vérifier que l'utilisateur est soit ADMIN, soit SUPER_ADMIN
        if (req.auth.userRole === 'USER') {
            return res.status(403).json({ message: "You do not have permission to create a user." });
        }

        if (!username) {
            return res.status(400).json({ message: "Username are required." });
        }

        if (!email) {
            return res.status(400).json({ message: "Email are required." });
        }

        if (!password) {
            return res.status(400).json({ message: "Password are required." });
        }

        // Si l'utilisateur tente de créer un rôle autre que 'USER'
        if (roles && roles !== 'USER') {
            // Vérifier si le rôle de l'utilisateur qui fait la requête est SUPER_ADMIN
            if (req.auth.userRole !== 'SUPER_ADMIN') {
                return res.status(403).json({ message: "Only SUPER_ADMIN can assign roles other than USER." });
            }
        }

        // Création de l'utilisateur avec les informations fournies
        const newUser = await User.create({
            username,
            email,
            password: await bcrypt.hash(password, 10),
            avatar,
            roles: roles || 'USER' // Par défaut, le rôle est USER
        });

        res.status(201).json(newUser);
    } catch (error) {
        res.status(500).json({
            message: error.message || 'An error occurred while creating the user.'
        });
    }
};


exports.update = async (req, res) => {
    try {
        const userId = req.params.id;
        const { username, email, roles, password } = req.body;

        if (req.auth.userRole === 'USER') {
            return res.status(403).json({ message: "Il faut être admin pour accéder à cette page." });
        }

        // Récupération de l'utilisateur cible
        const user = await User.findOne({ where: { id: userId } });
        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        // Vérification des permissions
        if (req.auth.userRole === 'ADMIN' && user.roles !== 'USER') {
            return res.status(403).json({ message: "Admins can only modify or delete users with role USER." });
        }

        if (username) user.username = username;
        if (email) user.email = email;
        if (password) user.password = await bcrypt.hash(password, 10);
        if (roles) {
            if(req.auth.userRole === 'SUPER_ADMIN') {
                user.roles = roles;
            } else {
                return res.status(403).json({ message: "Only SUPER_ADMIN can modify user roles." });
            }
        }

        await user.save();

        res.status(200).json(user);
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while updating the user.' });
    }
};

exports.delete = async (req, res) => {
    try {
        const userId = req.params.id;

        if (req.auth.userRole === 'USER') {
            return res.status(403).json({ message: "Il faut être admin pour accéder à cette page." });
        }

        // Récupération de l'utilisateur cible
        const user = await User.findOne({ where: { id: userId } });
        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        // Vérification des permissions
        if (req.auth.userRole === 'ADMIN' && user.roles !== 'USER') {
            return res.status(403).json({ message: "Admins can only delete users with role USER." });
        }

        await user.destroy();

        res.status(200).json({ message: "User deleted successfully." });
    } catch (error) {
        res.status(500).json({ message: error.message || 'An error occurred while deleting the user.' });
    }
};
