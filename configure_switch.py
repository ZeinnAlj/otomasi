import serial
import time

def configure_switch_via_console():
    # Set up the serial connection
    ser = serial.Serial('/dev/ttyUSB0', baudrate=9600, timeout=1)
    time.sleep(2)

    # Entering configuration mode
    ser.write(b'\r\n')
    ser.write(b'enable\r\n')
    ser.write(b'configure terminal\r\n')
    
    # Configure SSH
    ser.write(b'hostname Switch1\r\n')
    ser.write(b'ip domain-name zeze.com\r\n')
    ser.write(b'crypto key generate rsa\r\n')
    ser.write(b'username admin privilege 15 password cisco\r\n')
    ser.write(b'line vty 0 15\r\n')
    ser.write(b'login local\r\n')
    ser.write(b'transport input ssh\r\n')
    ser.write(b'exit\r\n')
    
    print("Initial configuration completed.")
    ser.close()

if __name__ == "__main__":
    configure_switch_via_console()
