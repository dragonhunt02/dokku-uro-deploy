#!/bin/bash
set -e;

# Set website domain
ROOT_URL="vsekai.local"

echo "Deploy setup started!";
echo "Domain: ${ROOT_URL}"

# (Optional) Setup letsencrypt email for SSL
# dokku traefik:set --global letsencrypt-email automated@example.com

# (Optional) Use letsencrypt staging server instead
# dokku traefik:set --global letsencrypt-server https://acme-staging-v02.api.letsencrypt.org/directory

# (Optional) Enable traefik dashboard. You must set a password for security.
# dokku traefik:set --global dashboard-enabled true
# dokku traefik:set --global basic-auth-username username
# dokku traefik:set --global basic-auth-password password

# (Optional) Set traefik dashboard hostname
# dokku traefik:set --global api-vhost traefik.vsekai.local

# Start traefik
dokku proxy:set --global traefik;
dokku nginx:stop;
dokku traefik:start;

# Install plugins
dokku plugin:install https://github.com/dokku/dokku-postgres.git --name postgres;
dokku plugin:install https://github.com/dokku/dokku-redis.git --name redis;
dokku plugin:install https://github.com/dragonhunt02/dokku-uro-deploy.git;

# Setup backend env
SETUP="ROOT_ORIGIN=https://${ROOT_URL}
URL=https://${ROOT_URL}/api/v1/
FRONTEND_URL=https://${ROOT_URL}/
REDIS_URL=redis://redis:6379
PHOENIX_KEY_BASE=bNDe+pg86uL938fQA8QGYCJ4V7fE5RAxoQ8grq9drPpO7mZ0oEMSNapKLiA48smR
JOKEN_SIGNER=gqawCOER09ZZjaN8W2QM9XT9BeJSZ9qc
TURNSTILE_SECRET_KEY=1x0000000000000000000000000000000AA
SIGNUP_API_KEY=eNoZ4kXHgT0z9ZTYGsq7eE0rQYvR6YBi
OAUTH2_GITHUB_STRATEGY=Assent.Strategy.Github
OAUTH2_GITHUB_CLIENT_ID=
OAUTH2_GITHUB_CLIENT_SECRET=
OAUTH2_DISCORD_STRATEGY=Assent.Strategy.Discord
OAUTH2_DISCORD_CLIENT_ID=
OAUTH2_DISCORD_CLIENT_SECRET=
PORT=4000";

SETUP="$(echo "$SETUP" | tr "\n" " ")";

# Setup uro backend
dokku apps:create uroapp;
dokku config:set uroapp $SETUP;

# Setup databases (:link will override database url environment variables)
export POSTGRES_CUSTOM_ENV="USER=vsekai;"
dokku postgres:create database -p vsekai || true;
dokku postgres:link database uroapp --no-restart;
dokku postgres:restart database;

dokku redis:create redisdb || true;
dokku redis:link redisdb uroapp --no-restart;
dokku redis:restart redisdb;

# Setup frontend
dokku apps:create nodeapp;
dokku builder:set nodeapp build-dir frontend;
dokku docker-options:add nodeapp build "--build-arg uro_image=dokku/uroapp";

# Required for traefik
dokku domains:add uroapp ${ROOT_URL}
dokku domains:add nodeapp ${ROOT_URL}

# Frontend requires a network to talk to backend. Url is API_ORIGIN frontend env variable
dokku network:create uronet
dokku network:set uroapp attach-post-deploy uronet
dokku network:set nodeapp attach-post-deploy uronet

# Setup frontend env
SETUP2="NEXT_PUBLIC_ORIGIN=https://${ROOT_URL}
API_ORIGIN=http://uroapp.web:5000
NEXT_PUBLIC_API_ORIGIN=https://${ROOT_URL}/api/v1
NEXT_PUBLIC_TURNSTILE_SITEKEY=1x00000000000000000000AA";

SETUP2="$(echo "$SETUP2" | tr "\n" " ")";
dokku config:set nodeapp $SETUP2;

echo "Deploy setup done!";
