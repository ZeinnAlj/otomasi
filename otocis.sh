#!/usr/bin/expect -f

# Set timeout
set timeout 20

# Define username, password, and IP Address of the Cisco Switch
set username "root"
set password "root"
set ip_address "192.168.36.2"

# Start SSH connection to the switch
spaw ssh root@192.168.36.2

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
