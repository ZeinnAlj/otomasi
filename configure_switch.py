import serial
import time

def configure_via_console(port, commands):
    ser = serial.Serial(port, baudrate=9600, timeout=1)
    time.sleep(2)  # Wait for connection
    
    for command in commands:
        ser.write(command.encode() + b'\n')
        time.sleep(1)
    
    output = ser.read(65535).decode()
    ser.close()
    return output

port = "/dev/ttyS0"  # Replace with the appropriate serial port
commands = ["enable", "configure terminal", "interface fa0/1", "description Automated_Config"]

output = configure_via_console(port, commands)
print(output)
