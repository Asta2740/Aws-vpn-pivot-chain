#!/bin/bash
set -e
./01_install_openvpn.sh
./02_generate_pki.sh
./03_configure_server.sh
./04_enable_forwarding.sh
./05_generate_client_profile.sh
./06_install_noip.sh
echo "Configure your client1.ovpn Change YOUR_DDNS to your No-IP DNS or the Server IP."
echo "Run THM OpenVPN manually, then execute ./07_enable_pivot_nat.sh to enable NAT routing."
