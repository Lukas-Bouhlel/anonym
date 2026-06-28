FROM node:22.12.0

WORKDIR /app

COPY package*.json ./

RUN npm install --legacy-peer-deps

COPY . .

RUN npm run build

EXPOSE 8080

CMD ["npm", "run", "preview", "--", "--host", "0.0.0.0"]
