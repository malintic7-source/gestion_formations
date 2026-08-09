FROM node:18-alpine
WORKDIR /usr/src/app
COPY package.json ./
RUN npm install --production
COPY server.js ./
# Copy bundled data (formations.json) so the API can seed initial formations
COPY data ./data
RUN mkdir -p /data
EXPOSE 5001
CMD ["node", "server.js"]
