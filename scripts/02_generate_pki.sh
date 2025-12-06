#!/bin/bash
set -e
directory_name="~/openvpn-ca"

if [ ! -d "$directory_name" ]; then
    mkdir "$directory_name"
    echo "Directory '$directory_name' created."
else
    echo "Directory '$directory_name' already exists."
fi
cd ~/openvpn-ca
./easyrsa init-pki
./easyrsa build-ca nopass
./easyrsa build-server-full server nopass
./easyrsa gen-dh
./easyrsa build-client-full client1 nopass
