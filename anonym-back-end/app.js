const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const app = express();
const router = require("./app/routes/index.js");
const db = require("./app/models/index.js");
const deviceInfoMiddleware = require('./app/middlewares/deviceInfo.js');

db.sequelize
    .authenticate()
    .then(() => console.log("Database connected..."))
    .catch((err) => console.log(err));

app.use(express.json());
app.use(cors(process.env.ORIGIN));

app.get('/', (req, res) => {
    res.send('Hello, world!');
});

app.use(cookieParser());
app.use(deviceInfoMiddleware);
app.use("/api", router);

module.exports = app;