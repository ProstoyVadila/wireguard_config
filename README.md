# Wireguard VPN Configuration

## TODO

1. Get a VPS instance somewhere.
2. Check a port for your vpn server. It should be open.
3. [Install `wireguard`.](#install-wireguard)
4. [Generate private and public keys for your server.](#keys-generation)
5. [Check your network configuration on your VPS (more likely `eth0`).](#check-network-configuration)
6. Create configuration file (use [`wg0.conf`](wg0.conf) as example).
7. [Set ip fastforwarding.](#set-fastforwarding)
8. Set your server configuration to the [script](add_user.sh)
9. [Add users](#add-users-script) running the [script](add_user.sh).
10. [Start system demon.](#system-deamon)
11. Download app to your client device.
12. Open your client config on your device.
13. Enjoy your little fictional piece of freedom. ヾ(⌐■_■)ノ ♪

## Wireguard Installation

```bash
apt update && apt -y upgrade
```

```bash
apt install -y wireguard
```

## Keys Generation

Don't copy! Use as example.

```bash
wg genkey | tee /etc/wireguard/<server_private_key_name> | wg pubkey | tee /etc/wireguard/<server_public_key_name>
```

Don't forget to set rights to your private key.

```bash
chmod 600 /etc/wireguard/<servier_private_key_name>
```

## Check Network Configuration

```bash
ip a
```

or

```bash
ifconfig
```

It is more likely `eth0`. It is used in example [config](wg0.conf). Just set yours.

## Set fastforwarding

```bash
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
```

## System deamon

Enable

```bash
systemctl enable wg-quick@wg0.service
```

\
Start

```bash
systemctl start wg-quick@wg0
```

\
Stop

```bash
systemctl stop wg-quick@wg0
```

\
Restart:

```bash
systemctl restart wg-quick@wg0
```

\
Check status:

```bash
systemctl status wg-quick@wg0
```

\
Check wireguard stats

```bash
wg show
```

## Add Users Script

Give it executable rights for the first time.

```bash
chmod +x add_user.sh
```

To add user:

```bash
./add_user.sh <user_name>
```

## Backups

if something goes wrong you can find a previous version of the server config in `/etc/wireguard/backup` folder
