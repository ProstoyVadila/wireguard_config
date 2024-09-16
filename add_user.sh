#!/bin/bash

# TODO: set your server configuration info here
SERVER_PUBLIC_KEY_NAME=
SERVER_IP=
DNS="8.8.8.8"  # example
CONFIG_TAG=vpn # example

# Consts
CLIENT_PRIVATE_KEY_NAME="$1"_privatekey # example
CLIENT_PUBLIC_KEY_NAME="$1"_publickey   # example
ALLOWED_IPS="0.0.0.0/0"                 # example
PERSISTENT_KEEP_ALIVE="20"              # example

CLIENT_CONFIG_PATH="./"
CLIENT_CONFIG_FILE="$1"_"$CONFIG_TAG".conf
CLIENT_CONFIG_FILEPATH="$CLIENT_CONFIG_PATH/$CLIENT_CONFIG_FILE"

CONFIG_PATH=/etc/wireguard
CONFIG_FILE=wg0.conf
CONFIG_FILEPATH="$CONFIG_PATH/$CONFIG_FILE"

BACKUP_FOLDER=/etc/wireguard/backup

set -e

# Check new client config name
if [ -z "$1" ]; then
    echo "Enter a username for the new vpn config"
    exit 1
fi

# Check if printf exists in that bash
if [ ! "$(command -v printf)" ]; then
    echo "command \"printf\" does not exists on system."
    echo "please, install \"printf\""
    exit 1
fi

# Checking installed wireguard
if [ ! -d "$CONFIG_PATH" ]; then
    printf "Cannot find a wireguard folder %s\n" "$CONFIG_PATH"
    exit 1
fi

# Createing/updating a folder of previous verions of the server config file
if [ ! -d "$BACKUP_FOLDER" ]; then
    mkdir $BACKUP_FOLDER
fi

# Checking config existance
if [[ ! -f $CONFIG_FILEPATH ]]; then
    echo "Cannot find the wireguard server config file $CONFIG_FILEPATH"
    exit 1
fi

# Copying the server config to backup folder
BACKUP_SERVER_CONFIG_FILEPATH="$BACKUP_FOLDER/$CONFIG_FILE-$(date +%Y-%m-%d)"
cp $CONFIG_FILEPATH "$BACKUP_SERVER_CONFIG_FILEPATH"

# Checking server public key existance
if [[ ! -f "$CONFIG_PATH/$SERVER_PUBLIC_KEY_NAME" ]]; then
    echo "Cannot find the server public key"
    exit 1
fi
SERVER_PUBLIC_KEY=$(cat "$CONFIG_PATH/$SERVER_PUBLIC_KEY_NAME")

# Getting the port of vpn server
SERVER_PORT=$(grep "ListenPort" $CONFIG_FILEPATH | awk '{print $3}')
if [ -z "$SERVER_PORT" ]; then
    echo "Cannot find a server port :("
    exit 1
fi
ENDPOINT="$SERVER_IP:$SERVER_PORT"

# Getting the last part of the last client IP
IP_ID=$(grep "10.0.0." $CONFIG_FILEPATH -c)
IP_ID=$((IP_ID + 1))
if [ -z "$IP_ID" ]; then
    echo "Cannot find a last client ip address"
    exit 1
fi
CLIENT_ADDRESS="10.0.0.$IP_ID/32"

# Generating the new client config
echo "Creating a pair of keys for the new client config..."
wg genkey | tee "$CONFIG_PATH/$CLIENT_PRIVATE_KEY_NAME" | wg pubkey | tee "$CONFIG_PATH/$CLIENT_PUBLIC_KEY_NAME"

CLIENT_PRIVATE_KEY=$(cat "$CONFIG_PATH/$CLIENT_PRIVATE_KEY_NAME")
CLIENT_PUBLIC_KEY=$(cat "$CONFIG_PATH/$CLIENT_PUBLIC_KEY_NAME")

# Adding the new client to the server config
echo "Adding the new client to the server config..."
{
    printf "\n[Peer]"
    printf "\nPublicKey = %s" "$CLIENT_PUBLIC_KEY"
    printf "\nAllowIPs = %s\n" "$CLIENT_ADDRESS"

} >>$CONFIG_FILEPATH

# Creating the new client config
echo "Creating a client config file..."
if [ -n "$CLIENT_CONFIG_PATH" ]; then
    mkdir -p $CLIENT_CONFIG_PATH
fi
touch "$CLIENT_CONFIG_FILEPATH"

{
    printf "[Interface]"
    printf "\nPrivateKey = %s" "$CLIENT_PRIVATE_KEY"
    printf "\nAddress = %s" "$CLIENT_ADDRESS"
    printf "\nDNS = %s" "$DNS"
    printf "\n"
    printf "\n[Peer]"
    printf "\nPublicKey = %s" "$SERVER_PUBLIC_KEY"
    printf "\nEndpoint = %s" "$ENDPOINT"
    printf "\nAllowedIPs = %s" "$ALLOWED_IPS"
    printf "\nPersistentKeepalive = %s\n" "$PERSISTENT_KEEP_ALIVE"

} >>"$CLIENT_CONFIG_FILEPATH"

# Restarting server
systemctl restart wg-quick@wg0
systemctl status wg-quick@wg0
wg show

printf "Successfully added user %s to vpn!\n" "$1"
printf "The new client configuration file is here %s\n" "$CLIENT_CONFIG_FILEPATH"
