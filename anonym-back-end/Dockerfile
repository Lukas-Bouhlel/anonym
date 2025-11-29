FROM node:20.19.6

WORKDIR /app

COPY package*.json ./

RUN npm install -g nodemon
RUN npm install -g sequelize-cli
RUN npm install

COPY . .

EXPOSE 5000

CMD [ "npm", "start" ]