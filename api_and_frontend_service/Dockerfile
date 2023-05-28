FROM php:7.4-apache

RUN docker-php-ext-install mysqli

# Use the default production configuration.
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
# Disallow access to the config directory.
RUN cat <<EOF >> "$APACHE_CONFDIR/apache2.conf"
<Directory "/var/www/html/config">
    Require all denied
</Directory>
EOF

COPY . /var/www/html/
