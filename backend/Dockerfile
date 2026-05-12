FROM node:22-bookworm-slim

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=7860
ENV SQLITE_PATH=/data/salonease.sqlite

COPY package*.json ./
RUN npm ci --omit=dev

COPY . .

RUN mkdir -p /data /app/uploads \
  && chown -R node:node /data /app

USER node

EXPOSE 7860

CMD ["npm", "start"]
