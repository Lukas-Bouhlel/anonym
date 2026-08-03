FROM node:26.5.1

WORKDIR /app

COPY package*.json ./

RUN npm install -g sequelize-cli
RUN npm ci --omit=dev --legacy-peer-deps

COPY . .

EXPOSE 5000

CMD [ "npm", "start" ]
