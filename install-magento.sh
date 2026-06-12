#!/bin/bash
set -e

cd /var/www/html

# ─── Esperar a que OpenSearch esté realmente listo ───────────────────────────
echo "⏳ Esperando OpenSearch en opensearch:9200..."
until curl -sf http://opensearch:9200/_cluster/health > /dev/null 2>&1; do
    echo "   OpenSearch no disponible aún, reintentando en 5s..."
    sleep 5
done
echo "✅ OpenSearch listo."

# ─── Instalación o upgrade ───────────────────────────────────────────────────
if [ ! -f "/var/www/html/app/etc/env.php" ]; then
    echo "🚀 Instalando Magento 2.4.9..."

    # Copiar auth.json al home de www-data/root para que Composer lo use
    if [ -f "/var/www/html/auth.json" ]; then
        mkdir -p /root/.composer
        cp /var/www/html/auth.json /root/.composer/auth.json
    fi

    # Crear proyecto (en directorio actual ya montado como volumen)
    composer create-project \
        --repository-url=https://repo.magento.com/ \
        magento/project-community-edition:2.4.9 \
        . \
        --no-interaction

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

    echo "✅ Magento instalado. Instalando Sample Data..."

    php bin/magento sampledata:deploy
    php bin/magento setup:upgrade
    php bin/magento setup:di:compile
    php bin/magento setup:static-content:deploy -f en_US
    php bin/magento indexer:reindex
    php bin/magento cache:flush

    echo "✅ Sample Data instalado."
    echo "🔗 Admin: ${MAGENTO_BASE_URL}/admin"
    echo "👤 Usuario: ${MAGENTO_ADMIN_USER}"

else
    echo "♻️  Magento ya instalado. Ejecutando setup:upgrade..."
    php bin/magento setup:upgrade
    php bin/magento cache:flush
fi

# ─── Configurar Varnish como FPC ─────────────────────────────────────────────
php bin/magento config:set system/full_page_cache/caching_application 2
php bin/magento config:set system/full_page_cache/varnish/access_list "localhost"
php bin/magento config:set system/full_page_cache/varnish/backend_host "web"
php bin/magento config:set system/full_page_cache/varnish/backend_port 80

# ─── Configurar Redis para cache y sesiones ───────────────────────────────────
php bin/magento setup:config:set \
    --cache-backend=redis \
    --cache-backend-redis-server="${REDIS_HOST}" \
    --cache-backend-redis-db=0 \
    --no-interaction

php bin/magento setup:config:set \
    --session-save=redis \
    --session-save-redis-host="${REDIS_HOST}" \
    --session-save-redis-log-level=3 \
    --session-save-redis-db=2 \
    --no-interaction

# ─── Permisos finales ─────────────────────────────────────────────────────────
chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 770 {} \;
find /var/www/html -type f -exec chmod 660 {} \;
chmod +x /var/www/html/bin/magento

echo "✅ Configuración completada!"
