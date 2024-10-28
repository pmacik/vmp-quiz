FROM node:16

WORKDIR /app

COPY package*.json ./
COPY . .

RUN make get-resources
RUN npm install

EXPOSE 8888

CMD ["node", "app.js"]
