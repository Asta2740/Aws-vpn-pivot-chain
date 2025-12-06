#!/bin/bash
set -e

cp ../configs/thm-openvpn.service /etc/systemd/system/thm-openvpn.service
sudo systemctl daemon-reload
sudo systemctl enable thm-openvpn
sudo systemctl start thm-openvpn
sudo systemctl status thm-openvpn