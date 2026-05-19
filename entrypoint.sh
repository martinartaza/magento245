#!/bin/bash

# Iniciar PHP-FPM
php-fpm8.2 -D

# Instalar Magento si no está instalado
/usr/local/bin/install-magento.sh

# Iniciar Nginx
nginx -g "daemon off;" &

# Iniciar cron
cron

# Mantener el contenedor vivo
tail -f /var/log/nginx/error.log /var/log/php/php-fpm.log