# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Dockerized Magento 2.4.9 Community Edition environment for `ituc.sebastianartaza.com`. The Magento source code lives in `./magento/` (gitignored) and is created on first container boot via Composer.

## Stack

- **PHP 8.5-FPM** + **Nginx** + **Cron** — all inside a single `web` container managed by supervisord
- **MySQL 8.0** — data persisted in `./mysql-data/` (gitignored)
- **OpenSearch 2.11.1** — search engine, data in `./opensearch-data/` (gitignored)
- **Redis 7.2** — cache (db 0) and sessions (db 2), data in `./redis-data/` (gitignored)
- **Varnish 7.4** — full-page cache, TTL 1 day; config in `./varnish/default.vcl`
- **Traefik** (external, pre-existing) — TLS termination + routing to Varnish

## Request flow

```
Internet → Traefik (external network) → Varnish :80 (traefik+internal) → web/Nginx (internal only)
```

Varnish bypasses cache for `/admin`, `/pub/media`, `/pub/static`, and non-GET/HEAD requests.

## Common commands

```bash
# Start (builds web image first)
docker compose --env-file .env up --build -d

# Stop
docker compose down

# Tail web container logs
docker compose logs -f web

# Shell into web container
docker exec -it magento-web bash

# Run any bin/magento command
docker exec magento-web php bin/magento <command>

# Most-used bin/magento commands
docker exec magento-web php bin/magento cache:flush
docker exec magento-web php bin/magento indexer:reindex
docker exec magento-web php bin/magento setup:upgrade
docker exec magento-web php bin/magento setup:di:compile
docker exec magento-web php bin/magento setup:static-content:deploy -f en_US
```

## First-time setup

1. Copy `env.example` → `.env` — **do not use `${DOMAIN}` interpolation inside `.env`; Docker does not expand variables within the same file.**
2. Copy `auth.json.example` → `magento/auth.json` with real Magento Marketplace public/private keys.
3. `docker compose --env-file .env up --build -d`

On first boot `install-magento.sh` runs `composer create-project` then `setup:install` + sample data + compile + deploy. This takes ~20–30 minutes. On subsequent boots it only runs `setup:upgrade` + `cache:flush`.

## Key files

| File | Purpose |
|---|---|
| `Dockerfile` | Builds the `web` image (Ubuntu 22.04 + PHP 8.2 + Nginx + Composer) |
| `docker-compose.yml` | Defines all services and their networks |
| `nginx.conf` | Nginx vhost — delegates to `magento/nginx.conf.sample` |
| `supervisord.conf` | Runs PHP-FPM + Nginx + Cron inside the single `web` container |
| `entrypoint.sh` | Container entrypoint: calls `install-magento.sh` then starts supervisord |
| `install-magento.sh` | First-boot install or subsequent-boot upgrade logic |
| `varnish/default.vcl` | Varnish cache policy |
| `.env` | Live secrets (gitignored) — copy from `env.example` |
| `magento/auth.json` | Composer credentials for repo.magento.com (gitignored) |
