# Use official Nginx image for static site
FROM nginx:1.25-alpine

# Remove default nginx configs
RUN rm -rf /etc/nginx/conf.d/*

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy static site files
COPY . /usr/share/nginx/html

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

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8080 || exit 1

CMD ["nginx", "-g", "daemon off;"]