# AWS VPN Pivot Chain  
A reproducible double-VPN setup used to route traffic:

```
Client → AWS OpenVPN (tun0) → THM VPN (tun1) → Target
```

This repository contains:
- OpenVPN server configuration  
- PKI generation scripts  
- DDNS setup  
- Tun0→Tun1 NAT pivot scripts  
- UFW firewall rules  
- Full automation script  

Anyone who follows this repo can rebuild the exact tunnel chain.

---

# 🚀 Architecture Diagram

```
+---------------+      tun0 (10.8.0.0/24)       +---------------------------+
|    CLIENT     | ----------------------------> |         AWS SERVER        |
| 10.8.0.2       | <---------------------------- | OpenVPN + THM Tunnel     |
+---------------+         response              +------------+--------------+
                                                        |
                                                        | tun1 (192.168.x.x)
                                                        v
                                                 +--------------+
                                                 |   THM NET    |
                                                 | 10.80.0.0/12 |
                                                 +--------------+
```

# 🧪 Testing

On AWS:
```
ping  your LAB machine
```

On client:
```
Connect to the Server VPN

Ping the LAB machine
```
