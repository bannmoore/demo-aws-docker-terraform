FROM node:8.10.0-alpine

WORKDIR /app

COPY package.json /app/package.json
RUN npm install --quiet

COPY app.js /app/app.js

EXPOSE 3000
ENTRYPOINT ["npm", "run"]
CMD ["start"]