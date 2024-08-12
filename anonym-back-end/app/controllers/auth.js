const { User } = require('../models');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { Op } = require('sequelize');

exports.base = async (req, res) => {
    try {
        const test = ['Test Api !']
        res.status(200).json({ test });
    } catch (error) {
        res.status(500).json({
            message: error.message || 'Could not read all wood'
        });
    }
};

exports.signup = async (req, res) => {
    try {
        const user = await User.create({
            ...req.body
        });

        res.status(201).json(user);
    } catch (error) {
        res.status(500).json({ 
            message: error.message || 'Could not create user' 
        });
    }
}

exports.login = async (req, res) => {
    try {
        const { identifier, password } = req.body;

        // Vérifiez que le champ 'identifier' et le mot de passe sont fournis
        if (!identifier || !password) {
            return res.status(400).json({ message: "Identifier and password are required." });
        }

        // Chercher l'utilisateur par email ou nom d'utilisateur
        const user = await User.findOne({
            where: {
                [Op.or]: [
                    { email: identifier },
                    { username: identifier }
                ]
            }
        });

        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        // Comparer le mot de passe
        const passwordMatch = await bcrypt.compare(password, user.password);

        if (!passwordMatch) {
            return res.status(401).json({ message: "Invalid password" });
        }

        // Générer le token JWT
        const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, { expiresIn: '10h' });
        
        res.status(200).json({ token, user });
    } catch (error) {
        res.status(500).json({
            message: error.message || 'An error occurred during login'
        });
    }
}