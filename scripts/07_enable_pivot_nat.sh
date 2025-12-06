#!/bin/bash
set -e

sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o tun1 -j MASQUERADE
sudo iptables -A FORWARD -i tun0 -o tun1 -j ACCEPT
sudo iptables -A FORWARD -i tun1 -o tun0 -j ACCEPT

sudo apt install -y iptables-persistent
sudo netfilter-persistent save