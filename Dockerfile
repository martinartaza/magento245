FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    software-properties-common \
    curl \
    wget \
    gnupg \
    git \
    unzip \
    zip \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libwebp-dev \
    libxpm-dev \
    libxml2-dev \
    libicu-dev \
    libxslt1-dev \
    libzip-dev \
    libbz2-dev \
    libonig-dev \
    libldap2-dev \
    libcurl4-openssl-dev \
    libgmp-dev \
    libmagickwand-dev \
    cron \
    supervisor \
    nginx \
    vim \
    htop \
    && rm -rf /var/lib/apt/lists/*

# Instalar PHP 8.5
RUN add-apt-repository ppa:ondrej/php -y && \
    apt-get update && apt-get install -y \
    php8.5-fpm \
    php8.5-cli \
    php8.5-common \
    php8.5-mysql \
    php8.5-zip \
    php8.5-gd \
    php8.5-curl \
    php8.5-xml \
    php8.5-mbstring \
    php8.5-bcmath \
    php8.5-intl \
    php8.5-soap \
    php8.5-xsl \
    php8.5-redis \
    php8.5-opcache \
    php8.5-apcu \
    php8.5-bz2 \
    php8.5-ldap \
    php8.5-gmp \
    php8.5-imagick \
    && rm -rf /var/lib/apt/lists/*

# Instalar Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Configurar PHP-FPM
RUN sed -i "s/memory_limit = .*/memory_limit = 2048M/" /etc/php/8.5/fpm/php.ini && \
    sed -i "s/max_execution_time = .*/max_execution_time = 3600/" /etc/php/8.5/fpm/php.ini && \
    sed -i "s/upload_max_filesize = .*/upload_max_filesize = 64M/" /etc/php/8.5/fpm/php.ini && \
    sed -i "s/post_max_size = .*/post_max_size = 64M/" /etc/php/8.5/fpm/php.ini

# Configurar Nginx
RUN rm /etc/nginx/sites-enabled/default
COPY nginx.conf /etc/nginx/sites-available/magento
RUN ln -s /etc/nginx/sites-available/magento /etc/nginx/sites-enabled/

# Configurar Supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Script de instalación automática
COPY install-magento.sh /usr/local/bin/install-magento.sh
RUN chmod +x /usr/local/bin/install-magento.sh

# Crear directorios
RUN mkdir -p /var/www/html && \
    mkdir -p /var/log/nginx && \
    mkdir -p /var/log/php && \
    mkdir -p /run/php && \
    chown -R www-data:www-data /var/www/html /var/log/nginx /var/log/php /run/php

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]