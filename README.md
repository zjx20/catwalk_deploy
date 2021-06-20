catwalk deploy
==============

## Server

```bash
sudo apt-get install -y jq
curl -s https://raw.githubusercontent.com/zjx20/catwalk_deploy/main/download.sh | bash -s
curl -O https://raw.githubusercontent.com/zjx20/catwalk_deploy/main/run_server.sh
chmod +x run_server.sh

secret=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 24)

cat <<-EOF > conf_server.json
{
  "app": "server",
  "catwalk": {
    "secret": "${secret}",
    "encrypt": "aes-128",
    "obfuscation": true,
    "datashard": 10,
    "parityshard": 0,
    "mtu": 1400
  },
  "tunnel": {
    "policy": "smart",
    "max_paths": 4,
    "probe_bw_period_sec": 1200
  },
  "kcp": {
    "smux_buf": 16777216,
    "smux_stream_buf": 2097152,
    "sock_buf": 16777216,
    "sndwnd": 4096,
    "rcvwnd": 4096
  },
  "log": {
    "level": "info",
    "file": "./server.log",
    "snmp_log": "./snmp_server.log",
    "rotate_size_mb": 100,
    "rotate_keeps": 5
  },
  "target": "builtin-socks-server",
  "target_": "127.0.0.1:12345",
  "binds": [
    {
      "protocol": "tcp",
      "addr": "0.0.0.0:12345"
    },
    {
      "protocol": "udp",
      "addr": "0.0.0.0:12345"
    }
  ]
}
EOF

echo "secret is: ${secret}"

sudo apt-get install -y firewalld

# add the port to whitelist
sudo firewall-cmd --permanent --add-port 12345/tcp

# apply changes and check the status
sudo firewall-cmd --reload
sudo firewall-cmd --list-ports

# start the server
./run_server.sh
```
