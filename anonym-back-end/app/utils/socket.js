module.exports = (io) => {
    io.on('connection', (socket) => {
        console.log('A user connected:', socket.id);

        // Authentifier les utilisateurs via le token JWT
        socket.on('authenticate', (token) => {
            // Vérifier le token JWT
            const user = verifyToken(token); // Implémenter la vérification du token ici
            if (user) {
                socket.user = user;
                console.log('User authenticated:', user.userId);
            } else {
                socket.disconnect();
            }
        });

        // Écouter les messages privés
        socket.on('private_message', (data) => {
            const { receiverId, content } = data;
            if (socket.user) {
                // Envoyer le message au destinataire
                io.to(receiverId).emit('private_message', { senderId: socket.user.userId, content });
            }
        });

        // Gérer la déconnexion
        socket.on('disconnect', () => {
            console.log('User disconnected:', socket.id);
        });
    });
};

function verifyToken(token) {
    // Implémenter la logique pour vérifier le token JWT
    // Retourner l'utilisateur s'il est valide
}