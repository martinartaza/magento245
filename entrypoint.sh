#!/bin/bash

# Iniciar PHP-FPM
php-fpm8.5 -D

# Iniciar Nginx
nginx -g "daemon off;" &

# Iniciar cron (opcional)
cron

# Mantener el contenedor corriendo y mostrar logs
echo "✅ Servicios iniciados: PHP-FPM, Nginx"
echo "📝 Puedes ejecutar comandos manualmente con: docker compose exec web /bin/bash"
echo "📋 Logs en tiempo real:"

# Mostrar logs de nginx y php-fpm en tiempo real
tail -f /var/log/nginx/error.log /var/log/php/php-fpm.log