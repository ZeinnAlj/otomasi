#!/bin/bash
set -e

# Menambah Repositori Kartolo
cat <<EOF | sudo tee /etc/apt/sources.list
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-updates main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-security main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-backports main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-proposed main restricted universe multiverse
EOF

# Update Repositori
sudo apt update

# Install Isc-Dhcp-Server, IPTables, Dan Iptables-Persistent
sudo apt install sshpass
sudo apt install expect
sudo apt install -y isc-dhcp-server iptables iptables-persistent

# Konfigurasi DHCP
cat <<EOF | sudo tee /etc/dhcp/dhcpd.conf
subnet 192.168.36.0 netmask 255.255.255.0 {
    range 192.168.36.10 192.168.36.100;
    option routers 192.168.36.1;
    option domain-name-servers 8.8.8.8, 8.8.4.4;
}
EOF

# Konfigurasi Interfaces DHCP
sudo sed -i 's/^INTERFACESv4=.*/INTERFACESv4="eth1.10"/' /etc/default/isc-dhcp-server

# Konfigrasi IP Statis Untuk Internal Network menggunakan Netplan
cat <<EOF | sudo tee /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
    eth1:
      dhcp4: no
  vlans:
    eth1.10:
      id: 10
      link: eth1
      addresses: [192.168.36.1/24]
EOF

# Terapkan Konfigurasi Netplan dan Aktifkan Interface
echo "Mengaktifkan interface jaringan..."
sudo ip link set eth1 up
sudo netplan apply

# Restart DHCP Server
echo "Merestart DHCP server..."
sudo systemctl restart isc-dhcp-server

# Mengaktifkan IP Forwarding Dan Mengonfigurasi IPTables
echo "Mengonfigurasi IP Forwarding dan IPTables..."
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Menyimpan Aturan IPTables
sudo netfilter-persistent save

echo "Otomasi konfigurasi selesai."
