from netmiko import ConnectHandler

def configure_switch_via_ssh():
    # Device details
    device = {
        'device_type': 'cisco_ios',
        'host': '192.168.36.2',  # Replace with the switch's IP
        'username': 'admin',
        'password': 'cisco',
    }

    # Connect to the device
    net_connect = ConnectHandler(**device)
    net_connect.enable()

    # Commands to configure
    commands = [
        "interface vlan 10",
        "ip address 192.168.36.3 255.255.255.0",
        "no shutdown",
        "exit",
        "banner motd #Welcome to the switch!#",
    ]
    output = net_connect.send_config_set(commands)
    print(output)

    net_connect.disconnect()

if __name__ == "__main__":
    configure_switch_via_ssh()
