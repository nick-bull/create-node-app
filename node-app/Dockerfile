FROM node:14
WORKDIR /var/nodejs

COPY package*.json ./

RUN npm install

COPY . .

CMD [ "npm", "start" ]

