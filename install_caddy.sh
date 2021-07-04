#!/bin/bash

set -e

if which dpkg > /dev/null 2>&1 ; then
  arch=$(dpkg --print-architecture)
else
  # full list https://unix.stackexchange.com/a/353375
  case $(uname -m) in
  aarch64)
    arch=arm64
    ;;
  *)
    echo "ERROR: can't determine OS architechure"
    exit 1
    ;;
  esac
fi

os=$(uname -s | tr A-Z a-z)
arch=$(dpkg --print-architecture)
file_name="caddy"
download_url="https://caddyserver.com/api/download?os=${os}&arch=${arch}&idempotency=78451960045094"

wget -O "$file_name" "$download_url"

sudo mv caddy /usr/bin/
sudo groupadd -f --system caddy
sudo useradd -f --system \
    --gid caddy \
    --create-home \
    --home-dir /var/lib/caddy \
    --shell /usr/sbin/nologin \
    --comment "Caddy web server" \
    caddy

sudo mkdir /etc/caddy
sudo chown -R root:root /etc/caddy
sudo mkdir /etc/ssl/caddy
sudo chown -R root:caddy /etc/ssl/caddy
sudo chmod 0770 /etc/ssl/caddy

sudo touch /etc/caddy/Caddyfile
sudo chown root:root /etc/caddy/Caddyfile
sudo chmod 644 /etc/caddy/Caddyfile

sudo mkdir /var/lib/caddy/www
sudo chown caddy:caddy /var/lib/caddy/www
sudo chmod 555 /var/lib/caddy/www

sudo mkdir -p /var/lib/caddy/www/example.com
sudo bash -c "cat <<EOT > /var/lib/caddy/www/example.com/index.html
my site
EOT"
sudo chown -R caddy:caddy /var/lib/caddy/www/example.com
sudo chmod -R 555 /var/lib/caddy/www/example.com

sudo bash -c "cat <<EOT > /etc/caddy/Caddyfile
example.com {
  root * /var/lib/caddy/www/example.com
  file_server
  # use "tls internal" for self-signed certifications
  tls foo@gmail.com
  proxy /chat localhost:51283 {
    # websocket just works without explicitly enable
    header_up -Origin
  }
}
EOT"

sudo wget -O /etc/systemd/system/caddy.service https://raw.githubusercontent.com/caddyserver/dist/master/init/caddy.service

sudo systemctl daemon-reload
sudo systemctl enable caddy
sudo systemctl start caddy
