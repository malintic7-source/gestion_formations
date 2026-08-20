# Stage 1: Build Flutter app
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml ./
COPY pubspec.lock* ./

# Get dependencies
RUN flutter pub get

# Copy source code
COPY . .

# Build web app
RUN flutter build web --release --no-web-resources-cdn

# Stage 2: Runtime with nginx
FROM nginx:alpine

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built web files from builder stage
COPY --from=builder /app/build/web /usr/share/nginx/html

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q -O /dev/null http://localhost/ || exit 1

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
