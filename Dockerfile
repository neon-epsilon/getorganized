FROM php:7.4-apache

RUN docker-php-ext-install mysqli

# Use the default production configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

COPY backend/api /var/www/html/backend/api
COPY backend/lib /var/www/html/backend/lib
COPY static/ /var/www/html/static/
COPY index.html /var/www/html/
COPY config/ /var/www/html/config
