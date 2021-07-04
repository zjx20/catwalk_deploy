#!/bin/bash

set -e

if which dpkg > /dev/null 2>&1 ; then
  arch=$(dpkg --print-architecture)
else
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
asset_name="catwalk_${os}_${arch}.tar.gz"

release_info=$(curl -s -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/zjx20/catwalk_deploy/releases/latest)
release_name=$(echo "$release_info" | jq -r '.name')
download_url=$(echo "$release_info" | jq -r --arg name "$asset_name" '.assets | map(select(.name == $name)) | .[0].browser_download_url')
file_name="catwalk_${os}_${arch}_${release_name}.tar.gz"

wget -O /tmp/"$file_name" "$download_url"
cd /tmp
tar xvf "$file_name"

sudo cp server /usr/local/bin/catwalk_server

sudo mkdir -p /var/lib/catwalk
sudo chmod 755 /var/lib/catwalk
sudo touch /var/lib/catwalk/conf_server.json
sudo bash -c 'echo "{}" > /var/lib/catwalk/conf_server.json'
sudo chmod 755 /var/lib/catwalk/conf_server.json

sudo wget -O /etc/systemd/system/catwalk.service https://raw.githubusercontent.com/zjx20/catwalk_deploy/main/catwalk.service

sudo systemctl daemon-reload
sudo systemctl enable catwalk
# sudo systemctl start catwalk

# journalctl -u catwalk
