#!/bin/bash
set -e
cd /root/openvpn-ca

cat > client1.ovpn <<EOF
client
dev tun
proto udp
remote YOUR_DDNS 1194
resolv-retry infinite
nobind

<ca>
$(cat pki/ca.crt)
</ca>

<cert>
$(cat pki/issued/client1.crt)
</cert>

<key>
$(cat pki/private/client1.key)
</key>

cipher AES-256-CBC
auth SHA256
verb 3
EOF
