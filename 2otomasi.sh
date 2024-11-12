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

# 4. Konfigurasi Cisco Switch melalui SSH dengan username dan password root
echo "Mengonfigurasi Cisco Switch..."

#!/usr/bin/expect -f

# Set timeout
set timeout 20

# Define username, password, and IP Address of the Cisco Switch
set username "root"
set password "root"
set ip_address "192.168.36.2"

# Start SSH connection to the switch
spawn ssh root@192.168.36.2

# Handle the login prompt
expect "Password:"
send "root\r"

# Wait for the prompt after login
expect ">" 

# Enter privileged exec mode
send "enable\r"
expect "Password:"
send "root\r"

# Wait for the prompt
expect "#"

# Enter global configuration mode
send "configure terminal\r"
expect "(config)#"

# Configure interface e0/0 as trunk
send "interface ethernet0/0\r"
expect "(config-if)#"
send "switchport mode trunk\r"
send "exit\r"

# Configure interface e0/1 as access VLAN 10
send "interface ethernet0/1\r"
expect "(config-if)#"
send "switchport mode access\r"
send "switchport access vlan 10\r"
send "exit\r"

# Exit the configuration mode
send "end\r"
expect "#"

# Save the configuration
send "write memory\r"
expect "#"

# Exit the SSH session
send "exit\r"

# End of script

# 5. Konfigurasi MikroTik melalui SSH tanpa prompt
echo "Mengonfigurasi MikroTik..."
if [ -z "" ]; then
    ssh -p"1" -o StrictHostKeyChecking=no admin@192.168.234.1 <<EOF
ip address add address=192.168.36.2/24 interface=ether1      
ip address add address=192.168.200.1/24 interface=ether2     
EOF
else
    sshpass -p "1" ssh -o StrictHostKeyChecking=no admin@192.168.234.1 <<EOF
ip address add address=192.168.36.2/24 interface=ether1      
ip address add address=192.168.200.1/24 interface=ether2     
EOF
fi

# Konfigurasi Routing untuk jaringan MikroTik
echo "Menambahkan konfigurasi routing..."
sudo ip route add 192.168.200.0/24 via 192.168.36.2 || echo "Gagal menambahkan route. Pastikan jaringan MikroTik aktif."

echo "Otomasi konfigurasi selesai."
