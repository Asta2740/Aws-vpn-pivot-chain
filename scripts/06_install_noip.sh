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
