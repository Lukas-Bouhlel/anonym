const express = require('express');
const { createServer } = require('node:http');
const socketIo = require('socket.io');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const app = express();
const server = createServer(app);
const router = require("./app/routes/index.js");
const db = require("./app/models/index.js");
const path = require('path');
const initializeSocket = require('./app/utils/socket');

db.sequelize
    .authenticate()
    .then(() => console.log("Database connected..."))
    .catch((err) => console.log(err));

const io = socketIo(server, {
    cors: {
        origin: process.env.ORIGIN,
        methods: ["GET", "POST"]
    }
});

app.use(express.json());
app.use(cors(process.env.ORIGIN));
app.use(cookieParser());
app.use("/uploads", express.static(path.join(__dirname, "uploads")));
app.use("/api", router);

initializeSocket(io);

module.exports = app;