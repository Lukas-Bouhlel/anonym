FROM node:20.16.0

WORKDIR /app

COPY package*.json ./

ENV NODE_ENV=production
RUN npm install -g nodemon
RUN npm install -g sequelize-cli
RUN npm install

COPY . .

EXPOSE 5000

CMD [ "npm", "start" ]