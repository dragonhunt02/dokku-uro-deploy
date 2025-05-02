# dokku-uro-deploy
## Guide for uro test deployment

This is a test deployment for uro server. It runs Dokku in a docker container ([Container Guide](https://dokku.com/docs/getting-started/install/docker/)).

## Setup Dokku test container
Run in repository
```
docker compose up
```

Dokku will mount files in container from `/var/lib/dokku`

## Setup ssh
```
# Generate ssh key (don't set password)
ssh-keygen -t rsa -b 4096 -C "example@example.com" -P "" -f ~/.ssh/dokku
```

## Setup git repository
```
# Clone uro server
git clone https://github.com/V-Sekai/uro.git

# Setup git ssh user
echo 'Host dokku.local
  HostName 127.0.0.1
  Port 3022
  User git
  IdentityFile ~/.ssh/dokku' > ~/.ssh/config

# Add remote
cd uro
git remote add dokku dokku@dokku.local:uroapp
git remote add dokku2 dokku@dokku.local:nodeapp
```

Before deploy, you need to setup plugins and environment variables

You can run commands below in a local dokku container or through ssh on target container/machine with dokku installed

## Setup Dokku git ssh
### Add public key to dokku
Local Container
```
DOKKU_PUB_KEY=$( cat ~/.ssh/dokku.pub )
docker exec -it dokku bash -c "echo \"$DOKKU_PUB_KEY\" | dokku ssh-keys:add DOKKU_KEYNAME"
```
SSH
```
DOKKU_PUB_KEY=$( cat ~/.ssh/dokku.pub )
ssh user@host bash -c "echo \"$DOKKU_PUB_KEY\" | dokku ssh-keys:add DOKKU_KEYNAME"
```

## Dokku deploy setup
Environment variables can be changed in `deploy.sh`

Local Container
```
docker exec -i dokku bash < "deploy.sh"
```
SSH
```
ssh user@host bash < "deploy.sh"
```

## Deploy
To deploy server run:
```
git push dokku master
git push dokku2 master
```
Input `yes` if asked `The authenticity of host '[127.0.0.1]:3022 ([127.0.0.1]:3022)' can't be established...`.

If you are using local Dokku container, server should be served on `localhost:8080` (port 80) and `localhost:8443`  (port 443).

## Test (Local Container)
### Setup hosts file
**Windows/Mac**

Add this line to **hosts** file
```
127.0.0.1 vsekai.local
127.0.0.1 dokku.local
```

**Linux**

Run
```
sudo bash -c 'echo "127.0.0.1 vsekai.local" >> /etc/hosts'
sudo bash -c 'echo "127.0.0.1 dokku.local" >> /etc/hosts'
```

You can preview website at http://vsekai.local:8080 and https://vsekai.local:8443

Current http/https proxy is traefik, you can test it at http://uroapp.dokku.local
