#!/bin/bash
set -e

# Crear directorios de log si no existen
mkdir -p /var/log/nginx /var/log/php /run/php
chown -R www-data:www-data /var/log/nginx /var/log/php /run/php

# Ejecutar instalación/upgrade de Magento
/usr/local/bin/install-magento.sh

# Arrancar todos los servicios via supervisord (PHP-FPM + Nginx + Cron)
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
