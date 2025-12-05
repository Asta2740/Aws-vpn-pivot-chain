#!/bin/bash
set -e

sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o tun2 -j MASQUERADE
sudo iptables -A FORWARD -i tun0 -o tun2 -j ACCEPT
sudo iptables -A FORWARD -i tun2 -o tun0 -j ACCEPT

sudo apt install -y iptables-persistent
sudo netfilter-persistent save