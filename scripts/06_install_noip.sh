#!/bin/bash
set -e
cd /usr/local/src
wget https://www.noip.com/client/linux/noip-duc-linux.tar.gz
tar xf noip-duc-linux.tar.gz
cd noip-*
make install
# Configure No-IP with your account details
noip2 -C
systemctl enable noip2
systemctl start noip2

# sudo nano /etc/systemd/system/noip2.service
# 
# [Unit]
# Description=No-IP Dynamic DNS Update Client
# After=network-online.target
# Wants=network-online.target

# [Service]
# Type=forking
# ExecStart=/usr/local/bin/noip2 -c /usr/local/etc/no-ip2.conf
# Restart=always

# [Install]
# WantedBy=multi-user.target


# sudo systemctl enable noip2
# sudo systemctl start noip2
# sudo systemctl status noip2
