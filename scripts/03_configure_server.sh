#!/bin/bash
set -e
cp ../configs/server.conf /etc/openvpn/server/server.conf
systemctl enable openvpn-server@server
systemctl restart openvpn-server@server
