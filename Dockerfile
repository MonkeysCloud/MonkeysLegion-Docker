ARG BASE_TAG=8.4-fpm-alpine
FROM php:${BASE_TAG} AS base

LABEL maintainer="MonkeysCloud <dev@monkeys.cloud>" \
      org.opencontainers.image.title="MonkeysLegion" \
      org.opencontainers.image.description="Nginx + PHP-FPM runtime for MonkeysLegion apps" \
      org.opencontainers.image.url="https://github.com/MonkeysCloud/monkeyslegion" \
      org.opencontainers.image.source="https://github.com/MonkeysCloud/monkeyslegion" \
      org.opencontainers.image.licenses="MIT"

# -------- system packages ----------
RUN apk add --no-cache --virtual build-deps $PHPIZE_DEPS \
    && apk add --no-cache nginx bash curl git mysql-client libpq icu-dev jpeg-dev libpng-dev oniguruma-dev libxml2-dev zlib-dev unzip tzdata supervisor
# -------- PHP extensions ----------
RUN docker-php-ext-install pdo pdo_mysql mbstring intl opcache bcmath exif gd xml

# -------- Composer ----------
COPY --from=composer:2.8 /usr/bin/composer /usr/bin/composer

# -------- Non-root runtime user ----------
RUN addgroup -g 82 -S www && adduser -u 82 -D -S -G www www
WORKDIR /var/www/html
COPY --chown=www:www . .

# -------- Nginx ----------
COPY docker/nginx.conf /etc/nginx/nginx.conf

# -------- Healthcheck ----------
COPY docker/healthcheck.sh /usr/local/bin/healthcheck
RUN chmod +x /usr/local/bin/healthcheck

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD /usr/local/bin/healthcheck || exit 1

# -------- Supervisor (single PID) ----------
COPY --chown=root:root docker/supervisord.conf /etc/supervisord.conf

EXPOSE 80
USER www

ENTRYPOINT ["/usr/bin/supervisord","-c","/etc/supervisord.conf"]