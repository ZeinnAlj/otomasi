#!/bin/bash
# Ensure Python script is in the same directory

set -e

# Menambah Repositori Kartolo
cat <<EOF | sudo tee /etc/apt/sources.list
deb http://kebo.pens.ac.id/ubuntu/ focal main restricted universe multiverse
deb http://kebo.pens.ac.id/ubuntu/ focal-updates main restricted universe multiverse
deb http://kebo.pens.ac.id/ubuntu/ focal-security main restricted universe multiverse
deb http://kebo.pens.ac.id/ubuntu/ focal-backports main restricted universe multiverse
deb http://kebo.pens.ac.id/ubuntu/ focal-proposed main restricted universe multiverse
EOF

# Update Repositori & Aplikasi
sudo apt update
sudo apt install python3 
sudo apt install python3-pip
pip3 install --upgrade cryptography
pip3 install --upgrade pyopenssl
pip3 install netmiko 
pip3 install paramiko
pip3 install pyserial
sudo apt install sshpass
sudo apt install expect
sudo apt install -y isc-dhcp-server iptables iptables-persistent

# Konfigurasi DHCP
cat <<EOF | sudo tee /etc/dhcp/dhcpd.conf
subnet 192.168.36.0 netmask 255.255.255.0 {
    range 192.168.36.10 192.168.36.100;
    option routers 192.168.36.1;
    option domain-name-servers 8.8.8.8;
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

# Ensure the script is executable: chmod +x configure_switch.sh

echo "Starting switch configuration..."

# Step 1: Console configuration
python3 configure_switch.py

# Step 2: SSH configuration
python3 configure_ssh.py

echo "Switch configuration complete!"


#Konfigurasi MikroTik melalui SSH
echo -e "${BIRU}Memeriksa koneksi ke MikroTik di 192.168.200.1..."
if ping -c 3 192.168.200.1 > /dev/null; then
    echo -e "Koneksi ke MikroTik berhasil. Melanjutkan konfigurasi MikroTik..."
    
    sshpass -p "admin" ssh -o StrictHostKeyChecking=no admin@192.168.200.1 <<EOF
interface vlan add name=vlan10 vlan-id=10 interface=ether1
ip address add address=192.168.36.1/24 interface=vlan10
ip address add address=192.168.200.1/24 interface=ether2
ip route add dst-address=192.168.26.0/24 gateway=192.168.36.1
EOF
else
    echo -e "Gagal terhubung ke MikroTik di 192.168.200.1. Periksa konfigurasi jaringan."
    exit 1
fi

echo -e "Otomasi konfigurasi selesai."
