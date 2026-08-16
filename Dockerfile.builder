FROM node:20-bookworm
WORKDIR /npm-seed
COPY package.json package-lock.json ./
RUN npm ci
