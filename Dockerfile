FROM node:22.21.1-alpine

WORKDIR /app

RUN apk upgrade --no-cache --available libcrypto3 libssl3 openssl

COPY package*.json ./
RUN npm install --omit=dev \
	&& npm cache clean --force \
	&& rm -rf /root/.npm /usr/local/lib/node_modules/npm

COPY . .

ENV NODE_ENV=production
EXPOSE 3000

CMD ["node", "index.js"]
