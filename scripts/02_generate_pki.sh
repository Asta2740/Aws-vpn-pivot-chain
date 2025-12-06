#!/bin/bash
set -e

directory_name="/root/openvpn-ca"

# Create directory only if missing
if [ ! -d "$directory_name" ]; then
    make-cadir "$directory_name"
    echo "Directory '$directory_name' created."
else
    echo "Directory '$directory_name' already exists."
fi

cd "$directory_name"

# ---------------------------
# 1) PKI INIT
# ---------------------------
if [ ! -d "pki" ]; then
    ./easyrsa init-pki
    echo "[OK] PKI initialized."
else
    echo "[SKIP] PKI already exists."
fi

# ---------------------------
# 2) CA CERT
# ---------------------------
if [ ! -f "pki/ca.crt" ]; then
    ./easyrsa build-ca nopass
    echo "[OK] CA created."
else
    echo "[SKIP] CA already exists."
fi

# ---------------------------
# 3) DH PARAMS
# ---------------------------
if [ ! -f "pki/dh.pem" ]; then
    ./easyrsa gen-dh
    echo "[OK] DH generated."
else
    echo "[SKIP] DH already exists."
fi

# ---------------------------
# 4) SERVER CERT/KEY
# ---------------------------
if [ ! -f "pki/issued/server.crt" ]; then
    ./easyrsa build-server-full server nopass
    echo "[OK] Server cert built."
else
    echo "[SKIP] Server cert already exists."
fi

# ---------------------------
# 5) CLIENT CERT: Client1
# ---------------------------
CLIENT="Client1"
if [ ! -f "pki/issued/${CLIENT}.crt" ]; then
    ./easyrsa build-client-full "$CLIENT" nopass
    echo "[OK] Client '$CLIENT' cert built."
else
    echo "[SKIP] Client '$CLIENT' cert already exists."
fi

# ---------------------------
# 6) COPY FILES TO /etc/openvpn/server
# ---------------------------
DEST="/etc/openvpn/server"

mkdir -p "$DEST"

copy_needed=false

# Check each file before copying
for f in pki/ca.crt pki/dh.pem pki/issued/server.crt pki/private/server.key; do
    filename="$(basename $f)"
    if [ ! -f "$DEST/$filename" ]; then
        sudo cp "$f" "$DEST/"
        echo "[OK] Copied $filename"
        copy_needed=true
    else
        echo "[SKIP] $filename already exists in $DEST"
    fi
done

if [ "$copy_needed" = false ]; then
    echo "[INFO] No files needed copying. Everything already in place."
fi

echo "🔥 All steps completed without wasting time."
