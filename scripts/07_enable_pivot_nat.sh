#!/bin/bash
set -e

iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o tun1 -j MASQUERADE
iptables -A FORWARD -i tun0 -o tun1 -j ACCEPT
iptables -A FORWARD -i tun1 -o tun0 -j ACCEPT

apt install -y iptables-persistent
netfilter-persistent save
