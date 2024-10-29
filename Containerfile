FROM node:16 as builder

WORKDIR /app

COPY package*.json ./
COPY . .

RUN make get-resources
RUN npm install

FROM node:16-slim as runner

COPY --from=builder /app/node_modules /app/node_modules
COPY --from=builder /app/public /app/public
COPY --from=builder /app/quizzes /app/quizzes
COPY --from=builder /app/views /app/views
COPY --from=builder /app/app.js /app/app.js
COPY --from=builder /app/package*.json /app/

WORKDIR /app

RUN ls -la .

EXPOSE 8888

CMD ["node", "app.js"]
