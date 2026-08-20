FROM node:22-alpine

# Set working directory
WORKDIR /usr/src/app

# Set node environment to production
ENV NODE_ENV=production

# Copy package files
COPY package.json package-lock.json* ./

# Install production dependencies only
RUN npm install --production && \
    npm cache clean --force

# Copy application code
COPY server.js ./

# Create data directory with proper permissions
RUN mkdir -p /data && \
    chown -R node:node /usr/src/app /data

# Entrypoint runs briefly as root to repair volume ownership, then drops to node.
RUN apk add --no-cache su-exec
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:5001/api/health').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"

EXPOSE 5001

ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
CMD ["node", "server.js"]
