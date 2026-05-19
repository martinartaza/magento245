#!/bin/bash

cd /var/www/html

# Verificar si Magento ya está instalado
if [ ! -f "/var/www/html/app/etc/env.php" ]; then
    echo "Instalando Magento 2.4.7..."

    # Copiar auth.json si existe
    if [ -f "/var/www/html/auth.json" ]; then
        cp /var/www/html/auth.json /var/www/html/auth.json
    fi

    # Crear proyecto
    composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition:2.4.7 . --no-interaction

    # Instalar Magento
    php bin/magento setup:install \
        --base-url="${MAGENTO_BASE_URL}" \
        --base-url-secure="${MAGENTO_BASE_URL_SECURE}" \
        --db-host="${DB_HOST}" \
        --db-name="${DB_NAME}" \
        --db-user="${DB_USER}" \
        --db-password="${DB_PASSWORD}" \
        --admin-firstname="${MAGENTO_ADMIN_FIRSTNAME}" \
        --admin-lastname="${MAGENTO_ADMIN_LASTNAME}" \
        --admin-email="${MAGENTO_ADMIN_EMAIL}" \
        --admin-user="${MAGENTO_ADMIN_USER}" \
        --admin-password="${MAGENTO_ADMIN_PASSWORD}" \
        --language="en_US" \
        --currency="USD" \
        --timezone="America/Chicago" \
        --use-rewrites=1 \
        --search-engine="opensearch" \
        --opensearch-host="opensearch" \
        --opensearch-port=9200 \
        --backend-frontname="admin"

    echo "✅ Magento instalado correctamente!"
    echo "🔗 Admin: ${MAGENTO_BASE_URL}/admin"
    echo "👤 Usuario: ${MAGENTO_ADMIN_USER}"
else
    echo "Magento ya está instalado. Ejecutando setup:upgrade..."
    php bin/magento setup:upgrade
    php bin/magento cache:flush
fi

# Configurar Varnish
php bin/magento config:set system/full_page_cache/caching_application 2
php bin/magento config:set system/full_page_cache/varnish/access_list "localhost"
php bin/magento config:set system/full_page_cache/varnish/backend_host "web"
php bin/magento config:set system/full_page_cache/varnish/backend_port 80

echo "✅ Configuración completada!"