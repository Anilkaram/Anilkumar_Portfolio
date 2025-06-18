# Stage 1: Build
FROM node:18-alpine as builder
WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm install

# Copy and build
COPY . .
RUN npm run build  # If using a framework like React/Vue
# (Remove if static HTML)

# Stage 2: Runtime
FROM nginx:1.25-alpine

# Remove default config
RUN rm -rf /etc/nginx/conf.d/*

# Copy built assets
COPY --from=builder /app/dist /usr/share/nginx/html  # For frameworks
# COPY ./ /usr/share/nginx/html  # For static HTML

# Copy custom Nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Set permissions
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html

# Health check
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost/ || exit 1

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]