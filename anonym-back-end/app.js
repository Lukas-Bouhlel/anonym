const express = require('express');
const { createServer } = require("http");
const { Server } = require("socket.io");
const cors = require('cors');
const cookieParser = require('cookie-parser');
const rateLimit = require('express-rate-limit'); 
const slowDown = require('express-slow-down'); 
const app = express();
const httpServer = createServer(app);
const helmet = require('helmet');
const router = require("./app/routes/index.js");
const db = require("./app/models/index.js");
const path = require('path');
const initializeSocket = require('./app/utils/socket');
const createMailer = require('./app/utils/mailer.js');

db.sequelize
    .authenticate()
    .then(() => console.log("Database connected..."))
    .catch((err) => console.log(err));

const mailerConfig = {
    service: 'gmail',
    auth: {
        user: process.env.MAIL_USER,
        pass: process.env.MAIL_PASS, 
    },
};
  
const mailer = createMailer(mailerConfig); // Instanciation de mailer

app.use((req, res, next) => {
    req.mailer = mailer; // Ajouter l'instance du mailer à l'objet req
    next();
});

app.use(express.json());

// Limiter le nombre de requêtes par IP
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 1000, // Limite chaque IP à 100 requêtes par fenêtre
    message: {
        message: "Trop de requêtes effectuées depuis cette adresse IP, veuillez réessayer plus tard.",
    },
});

app.use(limiter);

const speedLimiter = slowDown({
    windowMs: 15 * 60 * 1000, // Période de 15 minutes
    delayAfter: 50, // Commence à ralentir les requêtes après 50 requêtes dans la fenêtre
    delayMs: () => 500, // Délai fixe de 500 ms par requête supplémentaire
});

app.use(speedLimiter);

app.use(helmet());

// Configurer le CSP
app.use(helmet({
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],  // Autoriser les ressources provenant de la même origine
            imgSrc: ["'self'",  process.env.BACK_END_ORIGIN, "data:"],  // Permettre le chargement d'images depuis localhost:5000 et les données inline (pour les avatars par ex)
            scriptSrc: ["'self'", process.env.BACK_END_ORIGIN],  // Permettre les scripts depuis localhost:5000
            styleSrc: ["'self'", "'unsafe-inline'"],  // Permet les styles inline (facultatif)
            fontSrc: ["'self'", process.env.BACK_END_ORIGIN],  // Permettre les polices de caractères depuis localhost:5000
            connectSrc: ["'self'", process.env.BACK_END_ORIGIN], // Autoriser les connexions à localhost:5000 (pour les API, WebSocket, etc.)
            objectSrc: ["'none'"], // Bloquer les objets embarqués, par exemple Flash (sécurité)
            frameSrc: ["'none'"],  // Bloquer les iframes externes (sécurité)
        },
    },
    crossOriginEmbedderPolicy: false,  // Désactiver si vous avez des vidéos ou images cross-origin
    crossOriginResourcePolicy: { policy: "cross-origin" }, // Autoriser le chargement des ressources cross-origin
}));

app.use(cors({
    origin: process.env.ORIGIN, 
    credentials: true,  // Permet les cookies
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));

const io = new Server(httpServer, {
    cors: {
        origin: process.env.ORIGIN, 
        credentials: true,  // Permet les cookies
        methods: ['GET', 'POST', 'PUT', 'DELETE'],
        allowedHeaders: ['Content-Type', 'Authorization']
    }
});

httpServer.listen(3000);

initializeSocket(io);

app.use(cookieParser());
app.use("/uploads", express.static(path.join(__dirname, "uploads")));
app.use("/api", router);

module.exports = app;