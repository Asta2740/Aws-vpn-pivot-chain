# AWS VPN Pivot Chain  
A complete guide to building a double-VPN chain where your traffic routes:

```
Your Machine → AWS OpenVPN Server → TryHackMe OpenVPN Tunnel → Target Network
```

This setup allows you to:

- Route ALL traffic through AWS  
- Pivot traffic into TryHackMe (or any OpenVPN provider)  
- Maintain persistent tunnels via systemd  
- Build repeatable, cloud-hosted VPN chains  

This repository includes all configs, scripts, and systemd services needed to reproduce the setup.

---

# 📘 Overview of the Architecture

AWS acts as:

1. **Your OpenVPN server** (tun0)  
2. **A TryHackMe VPN client** (tun1)  
3. **A router that NATs traffic between the tunnels**  

Resulting in a chained VPN path:

Note : you might want Check the vpn interfaces via
```
ip addr
```
and configure the  07_enable_pivot_nat.sh Based on it

```
Client → AWS (tun0) → NAT → THM (tun1) → Target Machines
```

---
## Note

This works with THM Eu West (Ireland) server , if you need it to work with the others go to configs/server.conf and change  the following line 

push "route 10.80.0.0 255.240.0.0"

to
push "route 10.64.0.0 255.240.0.0" if you're connecting to  US East

or
push "route 10.49.0.0 255.240.0.0" if you're connecting to Mumbai

# 📂 Repository Structure

```
aws-vpn-pivot-chain/
│
├── README.md
│
├── configs/
│   ├── server.conf
│   ├── ufw-before.rules    (no longer used; SG replaces UFW if you're using AWS)
│   └── sysctl.conf
│
├── scripts/
│   ├── 01_install_openvpn.sh
│   ├── 02_generate_pki.sh
│   ├── 03_configure_server.sh
│   ├── 04_enable_forwarding.sh
│   ├── 05_setup_firewall.sh        (deprecated)
│   ├── 06_generate_client_profile.sh
│   ├── 07_install_noip.sh
│   ├── 08_enable_pivot_nat.sh
│   └── 09_install_thm_service.sh
│
└── systemd/
    └── thm-openvpn.service
```

---

#  1. Launch an AWS Instance

Use:

- Ubuntu 22.04 LTS  
 


## 🔥 AWS Security Group Rules

Instead of using UFW, configure the firewall at the AWS Security Group level.

| Type      | Protocol | Port | Source       | Purpose                               |
|-----------|----------|------|--------------|----------------------------------------|
| OpenVPN   | UDP      | 1194 | 0.0.0.0/0    | Allow client VPN connections           |
| SSH       | TCP      | 22   | Your IP      | Secure remote access                   |
| All Outbound | All | All  | 0.0.0.0/0    | Allow AWS → THM tunnel to function     |

**This replaces all server-side firewall configuration.**

---

#  2. Install OpenVPN + EasyRSA

```
sudo apt update && sudo apt install openvpn easy-rsa -y
```

---

#  3. Generate PKI (Certificates + Keys)

```
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


```

Copy keys:

```
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

```

---

#  4. Install server.conf

```
sudo cp ../configs/server.conf /etc/openvpn/server/server.conf
sudo systemctl enable openvpn-server@server
sudo systemctl restart openvpn-server@server
```

---

#  5. Enable IP Forwarding

```
sudo cp ../configs/sysctl.conf /etc/sysctl.conf
sudo sysctl -p
```

---

#  6. (Optional) Install No-IP DDNS

```
cd scripts
sudo  ./07_install_noip.sh
```

---

#  7. Configure TryHackMe VPN on AWS

Upload your THM `.ovpn` file:

```
sudo mv YOUR_THM.ovpn /etc/openvpn/thm.ovpn
```

If the file requires username/password:

```
sudo nano /etc/openvpn/auth.txt
```

Enter:

```
USERNAME
PASSWORD
```

Update your `.ovpn` file to use absolute path:

```
auth-user-pass /etc/openvpn/auth.txt
```

Test the tunnel:

```
sudo openvpn --config /etc/openvpn/thm.ovpn
```

You should now see an interface like `tun1`.

---

#  8. Enable NAT Between AWS VPN and THM Tunnel

Run the script:

```
sudo bash scripts/08_enable_pivot_nat.sh
```

This enables:

- NAT masquerading for 10.8.0.0/24 → tun1  
- Forwarding between tun0 ↔ tun1  
- Persistent firewall rules via iptables-persistent  

This is what allows:

```
Client → tun0 → tun1 → TryHackMe → Targets
```

---

#  9. Make the THM Tunnel Persistent (systemd)

Install the auto-start service:

```
sudo bash scripts/08_install_thm_service.sh
```

This installs:

```
/etc/systemd/system/thm-openvpn.service
```

Template:

```
[Unit]
Description=THM OpenVPN Tunnel
After=network.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/usr/sbin/openvpn --config /etc/openvpn/{YOUR_TryHackMe_CONFIG}.ovpn
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Enable + start:

```
sudo systemctl daemon-reload
sudo systemctl enable thm-openvpn
sudo systemctl start thm-openvpn
sudo systemctl status thm-openvpn
```

Now the THM tunnel:

- Runs after reboot  
- Survives SSH disconnect  
- Restarts automatically on failure  

---

#  10. Connect Your Local Machine to AWS VPN

Download your client profile:

```
client1.ovpn
```

Import into your OpenVPN client.

Verify IP routing:

```
ip route
```

You should now see **AWS’s public IP**.

Test TryHackMe reachability:

```
ping 10.200.0.1
```

If successful, your traffic is now flowing through:

```
Your PC → AWS → THM → Target Machines
```

---

#  Troubleshooting

### THM tunnel fails to start at boot  
Check logs:

```
sudo journalctl -u thm-openvpn -n 50
```

Most common fix: ensure all paths in `.ovpn` are **absolute**, not relative.

### Can't reach THM hosts  
Check NAT rules:

```
sudo iptables -t nat -L -n -v
```

Ensure there is a MASQUERADE rule for:

```
10.8.0.0/24 → tun1
```

---

#  Conclusion

You now have a fully functional VPN pivot chain that is:

- Cloud-hosted  
- Persistent  
- Secure  
- Reproducible  

Anyone following this guide can recreate the exact setup.

---

Enjoy your new infrastructure.
