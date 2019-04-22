FROM node:10-alpine
ENV NPM_CONFIG_LOGLEVEL info

RUN mkdir -p /opt/app
WORKDIR /opt/app

COPY package*.json ./
RUN npm install

COPY . .

RUN chown -R node:node /opt/app
USER node

CMD ["npm", "start"]
