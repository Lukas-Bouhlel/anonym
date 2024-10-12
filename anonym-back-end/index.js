require('dotenv').config();
const app = require("./app.js");
const port = process.env.PORT;
const fs = require('fs');
const path = require('path');
const { createServer } = require("https");
const { Server } = require("socket.io");
const initializeSocket = require('./app/utils/socket');

const httpsOptions = {
  key: fs.readFileSync(path.resolve(__dirname, 'server.key')), 
  cert: fs.readFileSync(path.resolve(__dirname, 'server.crt')),
};

const httpsServer = createServer(httpsOptions, app);

const io = new Server(httpsServer, {
  cors: {
      origin: process.env.ORIGIN, 
      credentials: true,
      methods: ['GET', 'POST', 'PUT', 'DELETE'],
      allowedHeaders: ['Content-Type', 'Authorization']
  }
});

httpsServer.listen(port, () => {
  console.log(`App and Socket.IO listening on port ${port}`);
});

initializeSocket(io);