FROM php:7.4-apache

RUN docker-php-ext-install mysqli

# Use the default production configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

COPY api_and_frontend_service /var/www/html/
