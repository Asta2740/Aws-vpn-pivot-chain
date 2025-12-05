# AWS VPN Pivot Chain  
A complete guide to building a double-VPN chain where your traffic routes:

```
Your Machine → AWS OpenVPN Server → TryHackMe OpenVPN Tunnel → Target Network
```

This setup allows you to:

- Route ALL traffic through AWS  
- Mask your home IP  
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

```
Client → AWS (tun0) → NAT → THM (tun1) → Target Machines
```

---

# 📂 Repository Structure

```
aws-vpn-pivot-chain/
│
├── README.md
│
├── configs/
│   ├── server.conf
│   ├── ufw-before.rules    (no longer used; SG replaces UFW)
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
- t2.micro or larger  
- Optional: Elastic IP for stability  

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
make-cadir ~/openvpn-ca
cd ~/openvpn-ca

./easyrsa init-pki
./easyrsa build-ca nopass

./easyrsa build-server-full server nopass
./easyrsa gen-dh
./easyrsa build-client-full client1 nopass
```

Copy keys:

```
sudo cp pki/{ca.crt,dh.pem} /etc/openvpn/server/
sudo cp pki/issued/server.crt /etc/openvpn/server/
sudo cp pki/private/server.key /etc/openvpn/server/
```

---

#  4. Install server.conf

```
sudo cp configs/server.conf /etc/openvpn/server/server.conf
sudo systemctl enable openvpn-server@server
sudo systemctl restart openvpn-server@server
```

---

#  5. Enable IP Forwarding

```
sudo cp configs/sysctl.conf /etc/sysctl.conf
sudo sysctl -p
```

---

#  6. (Optional) Install No-IP DDNS

```
cd scripts
sudo bash 07_install_noip.sh
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
sudo bash scripts/09_install_thm_service.sh
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
curl ifconfig.me
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
- Ideal for labs, red-team style routing, and identity separation  

Anyone following this guide can recreate the exact setup.

---

Enjoy your new infrastructure.
