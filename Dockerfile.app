# File: Dockerfile.app
# Multi-stage build for Laravel (PHP 8.3 FPM) with Composer + Node build for Vue/Vite

# ---- base PHP image with extensions ----
FROM php:8.3-fpm-alpine AS php-base

# System deps for common PHP extensions and optimizations
RUN apk add --no-cache \
      bash git curl zip unzip \
      icu-dev libzip-dev oniguruma-dev \
      postgresql-dev libpng-dev libjpeg-turbo-dev libwebp-dev freetype-dev \
      autoconf g++ make \
 && pecl install redis \
 && docker-php-ext-enable redis \
 && apk del autoconf g++ make

# PHP extensions
RUN docker-php-ext-configure gd --with-jpeg --with-webp --with-freetype \
 && docker-php-ext-install -j$(nproc) intl zip bcmath pdo pdo_pgsql gd opcache

WORKDIR /var/www/html

# ---- composer deps (no dev) ----
FROM composer:2 AS vendor
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --prefer-dist --no-progress --no-interaction --no-scripts
# Copy full app for autoload dump (faster classmap)
COPY . .
RUN composer install --no-dev --prefer-dist --no-progress --no-interaction \
 && composer dump-autoload --optimize

# ---- node build for frontend assets ----
FROM node:20-alpine AS node-build
WORKDIR /app
COPY package.json package-lock.json* pnpm-lock.yaml* yarn.lock* ./
RUN if [ -f package-lock.json ]; then npm ci; \
    elif [ -f pnpm-lock.yaml ]; then npm i -g pnpm && pnpm i --frozen-lockfile; \
    elif [ -f yarn.lock ]; then yarn install --frozen-lockfile; \
    else npm i; fi
# Copy only what Vite needs
COPY resources ./resources
COPY vite.config.* postcss.config.* tailwind.config.* tsconfig.* ./
# Public may contain icons/manifest
COPY public ./public
RUN npm run build

# ---- runtime image ----
FROM php-base AS app
ENV APP_ENV=production \
    PHP_OPCACHE_VALIDATE_TIMESTAMPS=0 \
    PHP_MEMORY_LIMIT=512M

WORKDIR /var/www/html

# Copy application code
COPY . .

# Bring in composer vendor and built assets
COPY --from=vendor /app/vendor ./vendor
COPY --from=node-build /app/public ./public

# Permissions for storage and cache
RUN chown -R www-data:www-data storage bootstrap/cache \
 && find storage -type d -exec chmod 775 {} \; \
 && find storage -type f -exec chmod 664 {} \; \
 && chmod -R 775 bootstrap/cache

# Opcache production recommendations
RUN { \
  echo 'opcache.enable=1'; \
  echo 'opcache.enable_cli=1'; \
  echo 'opcache.memory_consumption=256'; \
  echo 'opcache.interned_strings_buffer=16'; \
  echo 'opcache.max_accelerated_files=20000'; \
  echo 'opcache.validate_timestamps=0'; \
  echo 'opcache.save_comments=1'; \
} > /usr/local/etc/php/conf.d/opcache.ini

# Optional: optimize caches if env allows (won't fail build if .env missing)
RUN php -r "file_exists('.env') || copy('.env.example','.env');" \
 && php artisan key:generate --force || true \
 && php artisan config:cache || true \
 && php artisan route:cache || true \
 && php artisan view:cache || true

USER www-data

# Expose FPM port for Nginx
EXPOSE 9000
CMD ["php-fpm", "-F"]
