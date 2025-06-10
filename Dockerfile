# Stage 1: Build
FROM node:18-alpine as builder

# Install security updates and dependencies
RUN apk --no-cache upgrade && \
    apk --no-cache add curl

WORKDIR /app

# Copy package files first for better caching
COPY package*.json ./

# Install dependencies with audit
RUN npm install --production --audit

# Copy all files
COPY . .

# Verify no sensitive files are included
RUN find . -type f -name '*secret*' -o -name '*password*' -o -name '*key*' && \
    [ $(find . -type f -name '*secret*' -o -name '*password*' -o -name '*key*' | wc -l) -eq 0 ] || exit 1

# Stage 2: Runtime
FROM nginx:1.25-alpine

# Remove default nginx configs
RUN rm -rf /etc/nginx/conf.d/*

# Copy custom secure nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built assets
COPY --from=builder /app /usr/share/nginx/html

# Set secure permissions
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html && \
    find /usr/share/nginx/html -type d -exec chmod 755 {} + && \
    find /usr/share/nginx/html -type f -exec chmod 644 {} +

# Add security headers
RUN echo "add_header X-Content-Type-Options nosniff;" >> /etc/nginx/nginx.conf && \
    echo "add_header X-Frame-Options SAMEORIGIN;" >> /etc/nginx/nginx.conf && \
    echo "add_header X-XSS-Protection \"1; mode=block\";" >> /etc/nginx/nginx.conf

# Run as non-root user
USER nginx

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8080 || exit 1

CMD ["nginx", "-g", "daemon off;"]