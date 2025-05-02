#!/bin/bash
set -e;

echo "Deploy setup started!";

# Start traefik
dokku proxy:set --global traefik;
dokku nginx:stop;
dokku traefik:start;

# Install plugins
dokku plugin:install https://github.com/dokku/dokku-postgres.git --name postgres;
dokku plugin:install https://github.com/dokku/dokku-redis.git --name redis;

# Setup backend env
SETUP='ROOT_ORIGIN=https://vsekai.local
URL=https://vsekai.local/api/v1/
FRONTEND_URL=https://vsekai.local/
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
PORT=4000';

SETUP="$(echo "$SETUP" | tr "\n" " ")";

# Setup uro backend
dokku apps:create uroapp;
dokku config:set uroapp $SETUP;

# Setup databases (:link will override database url environment variables)
export POSTGRES_CUSTOM_ENV="USER=vsekai;"
dokku postgres:create database -p vsekai || true;
dokku postgres:link database uroapp --no-restart;
dokku postgres:restart database;

dokku redis:create redisdb;
dokku redis:link redisdb uroapp --no-restart;
dokku redis:restart redisdb;

# Setup frontend
dokku apps:create nodeapp;
dokku builder:set nodeapp build-dir frontend;
dokku docker-options:add nodeapp build "--build-arg uro_image=dokku/uroapp";

# Setup frontend env
SETUP2='NEXT_PUBLIC_ORIGIN=https://vsekai.local
API_ORIGIN=http://uro:4000
NEXT_PUBLIC_API_ORIGIN=https://vsekai.local/api/v1
NEXT_PUBLIC_TURNSTILE_SITEKEY=1x00000000000000000000AA';

SETUP2="$(echo "$SETUP2" | tr "\n" " ")";
dokku config:set nodeapp $SETUP2;

echo "Deploy setup done!";
